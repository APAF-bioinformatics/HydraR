#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        checkpointer.R
#' Author:      APAF Agentic Workflow
#' Purpose:     AgentDAG Checkpointer Interface and Implementations
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Checkpointer Interface
#'
#' @description
#' Abstract base class for AgentDAG checkpointers.
#'
#' @importFrom R6 R6Class
#' @export
Checkpointer <- R6::R6Class("Checkpointer",
    public = list(
        #' Save state
        #' @param thread_id String. Identifier for the execution thread.
        #' @param state AgentState object. The state to save.
        #' @return NULL (called for side effect).
        put = function(thread_id, state) {
            stop("Method 'put' must be implemented by subclass.")
        },

        #' Load state
        #' @param thread_id String. Identifier for the execution thread.
        #' @return AgentState object or NULL if not found.
        get = function(thread_id) {
            stop("Method 'get' must be implemented by subclass.")
        }
    )
)

#' MemorySaver Checkpointer
#'
#' @description
#' In-memory implementation of the Checkpointer interface.
#' Stores checkpoints in an R environment.
#'
#' @importFrom R6 R6Class
#' @export
MemorySaver <- R6::R6Class("MemorySaver",
    inherit = Checkpointer,
    public = list(
        #' @field storage Environment. Stores the states.
        storage = NULL,

        #' Initialize MemorySaver
        initialize = function() {
            self$storage <- new.env(parent = emptyenv())
        },

        #' Save state
        #' @param thread_id String.
        #' @param state AgentState object.
        put = function(thread_id, state) {
            stopifnot(is.character(thread_id) && length(thread_id) == 1)
            stopifnot(inherits(state, "AgentState"))

            # Deep copy the state data so future modifications don't alter the checkpoint
            state_copy <- list(
                data = as.list(state$data),
                reducers = state$reducers,
                schema = state$schema
            )
            assign(thread_id, state_copy, envir = self$storage)
            invisible(self)
        },

        #' Load state
        #' @param thread_id String.
        #' @return AgentState object or NULL.
        get = function(thread_id) {
            stopifnot(is.character(thread_id) && length(thread_id) == 1)
            if (exists(thread_id, envir = self$storage)) {
                state_copy <- get(thread_id, envir = self$storage)
                # Reconstruct AgentState object
                if (!exists("AgentState")) {
                    stop("AgentState class not found. Ensure it is loaded.")
                }
                restored_state <- AgentState$new(
                    initial_data = state_copy$data,
                    reducers = state_copy$reducers,
                    schema = state_copy$schema
                )
                return(restored_state)
            }
            return(NULL)
        }
    )
)

#' DuckDBSaver Checkpointer
#'
#' @description
#' Persistent implementation of the Checkpointer interface using DuckDB.
#' Supports both direct DBI connections and file paths.
#'
#' @importFrom R6 R6Class
#' @importFrom DBI dbExecute dbWriteTable dbGetQuery dbDisconnect dbConnect
#' @export
DuckDBSaver <- R6::R6Class("DuckDBSaver",
    inherit = Checkpointer,
    public = list(
        #' @field con DBIConnection.
        con = NULL,
        #' @field table_name String.
        table_name = "agent_checkpoints",

        #' Initialize DuckDBSaver
        #' @param con DBIConnection. Optional if db_path is provided.
        #' @param db_path String path to DuckDB file. Optional if con is provided.
        #' @param table_name Name of the table to store checkpoints in.
        initialize = function(con = NULL, db_path = NULL, table_name = "agent_checkpoints") {
            self$table_name <- table_name
            
            if (!is.null(db_path)) {
                if (!requireNamespace("duckdb", quietly = TRUE)) stop("duckdb package required for path-based initialization.")
                self$con <- DBI::dbConnect(duckdb::duckdb(), db_path)
            } else if (!is.null(con)) {
                self$con <- con
            } else {
                stop("Either 'con' or 'db_path' must be provided to DuckDBSaver.")
            }

            # Ensure the table exists
            if (inherits(self$con, "DBIConnection")) {
                DBI::dbExecute(self$con, sprintf("
                    CREATE TABLE IF NOT EXISTS %s (
                        thread_id VARCHAR PRIMARY KEY,
                        state_json JSON,
                        updated_at TIMESTAMP DEFAULT current_timestamp
                    )
                ", self$table_name))
            }
        },

        #' Save state
        #' @param thread_id String.
        #' @param state AgentState object.
        put = function(thread_id, state) {
            stopifnot(is.character(thread_id) && length(thread_id) == 1)
            stopifnot(inherits(state, "AgentState"))

            state_data <- list(
                data = as.list(state$data),
                schema_keys = names(state$schema)
            )

            state_json <- jsonlite::toJSON(state_data, auto_unbox = TRUE, force = TRUE)

            # Upsert logic (DuckDB specific)
            DBI::dbExecute(self$con, sprintf("
                INSERT INTO %s (thread_id, state_json, updated_at)
                VALUES (?, ?, current_timestamp)
                ON CONFLICT (thread_id) DO UPDATE SET
                    state_json = excluded.state_json,
                    updated_at = excluded.updated_at
            ", self$table_name), params = list(thread_id, state_json))
            
            invisible(self)
        },

        #' Load state
        #' @param thread_id String.
        #' @return AgentState object or NULL.
        get = function(thread_id) {
            stopifnot(is.character(thread_id) && length(thread_id) == 1)

            df <- DBI::dbGetQuery(self$con, sprintf("SELECT state_json FROM %s WHERE thread_id = ?", self$table_name), params = list(thread_id))
            
            if (nrow(df) > 0) {
                state_data <- jsonlite::fromJSON(df$state_json[1], simplifyVector = FALSE)
                if (!exists("AgentState")) {
                    stop("AgentState class not found. Ensure it is loaded.")
                }
                # Return data wrapped in AgentState
                return(AgentState$new(initial_data = state_data$data))
            }
            return(NULL)
        }
    )
)

# <!-- APAF Bioinformatics | checkpointer.R | Approved | 2026-03-28 -->

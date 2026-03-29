# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        checkpointer.R
# Author:      APAF Agentic Workflow
# Purpose:     AgentDAG Checkpointer Interface and Implementations
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Checkpointer Interface
#'
#' @description
#' Abstract base class for AgentDAG checkpointers.
#'
#' @importFrom R6 R6Class
#' @export
Checkpointer <- R6::R6Class("Checkpointer",
  public = list(
    #' @description Persist state to the checkpointer.
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
    #' @description
    #' Creates a new environment for in-memory checkpoint storage.
    initialize = function() {
      self$storage <- new.env(parent = emptyenv())
    },

    #' @description Persist state to the checkpointer.
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

    #' @description Load state from the checkpointer.
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

#' RDS File Checkpointer
#'
#' @description
#' Lightweight file-based checkpointer using base R `saveRDS`/`readRDS`.
#' Each thread is persisted as a separate `.rds` file in the specified directory.
#' No external dependencies required.
#'
#' @importFrom R6 R6Class
#' @export
RDSSaver <- R6::R6Class("RDSSaver",
  inherit = Checkpointer,
  public = list(
    #' @field dir String. Directory to store .rds checkpoint files.
    dir = NULL,

    #' Initialize RDSSaver
    #' @param dir String. Directory path for checkpoint files.
    initialize = function(dir = "checkpoints") {
      self$dir <- dir
      if (!dir.exists(self$dir)) dir.create(self$dir, recursive = TRUE)
    },

    #' @description Persist state to an .rds file.
    #' @param thread_id String.
    #' @param state AgentState object.
    put = function(thread_id, state) {
      stopifnot(is.character(thread_id) && length(thread_id) == 1)
      stopifnot(inherits(state, "AgentState"))

      state_copy <- list(
        data = as.list(state$data),
        reducers = state$reducers,
        schema = state$schema
      )

      rds_path <- file.path(self$dir, paste0(thread_id, ".rds"))
      saveRDS(state_copy, rds_path)
      invisible(self)
    },

    #' @description Load state from an .rds file.
    #' @param thread_id String.
    #' @return AgentState object or NULL.
    get = function(thread_id) {
      stopifnot(is.character(thread_id) && length(thread_id) == 1)

      rds_path <- file.path(self$dir, paste0(thread_id, ".rds"))
      if (file.exists(rds_path)) {
        state_copy <- readRDS(rds_path)
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
                        state_json TEXT,
                        updated_at TIMESTAMP DEFAULT current_timestamp
                    )
                ", self$table_name))
      }
    },

    #' Save state
    #' @param thread_id String.
    #' @param state AgentState object.
    put = function(thread_id, state) {
      if (!is.character(thread_id) || length(thread_id) != 1) {
        stop("thread_id must be a single string.")
      }
      if (!inherits(state, "AgentState")) {
        stop(sprintf("state must be an AgentState object (received: %s).", class(state)[1]))
      }

      state_list <- state$to_list_serializable()
      state_json <- jsonlite::toJSON(state_list, auto_unbox = TRUE, pretty = TRUE)

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
      if (!is.character(thread_id) || length(thread_id) != 1) {
        stop("thread_id must be a single string.")
      }

      df <- DBI::dbGetQuery(self$con, sprintf("SELECT state_json FROM %s WHERE thread_id = ?", self$table_name), params = list(thread_id))

      if (nrow(df) > 0) {
        state_list <- jsonlite::fromJSON(df$state_json[[1]], simplifyVector = FALSE)
        # Re-hydrate AgentState
        restored_state <- AgentState$new(
          initial_data = state_list$data,
          reducers = state_list$reducers,
          schema = state_list$schema
        )
        return(restored_state)
      }
      return(NULL)
    }
  )
)

#' <!-- APAF Bioinformatics | checkpointer.R | Approved | 2026-03-29 -->

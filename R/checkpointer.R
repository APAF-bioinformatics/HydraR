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
#' An abstract base class defining the contract for state persistence and
#' recovery in HydraR. Checkpointers allow a DAG to be paused and resumed
#' across sessions by saving the \code{AgentState} after each node execution.
#'
#' @importFrom R6 R6Class
#' @return A \code{Checkpointer} object.
#'
#' @examples
#' \dontrun{
#' # Checkpointers are used within AgentDAG$run()
#' # Use a concrete implementation like RDSSaver or DuckDBSaver.
#' }
#' @export
Checkpointer <- R6::R6Class("Checkpointer",
  public = list(
    #' @description Persist state to the checkpointer.
    #' @param thread_id String.
    #' A unique identifier for the execution thread or session.
    #' @param state AgentState.
    #' The \code{AgentState} object to be persisted.
    #' @return NULL (called for side effect).
    put = function(thread_id, state) {
      stop("Method 'put' must be implemented by subclass.")
    },

    #' Load state from the checkpointer
    #' @param thread_id String.
    #' The unique identifier associated with the saved state.
    #' @return AgentState object or NULL if no checkpoint is found for the thread.
    get = function(thread_id) {
      stop("Method 'get' must be implemented by subclass.")
    }
  )
)

#' MemorySaver Checkpointer
#'
#' @description
#' An in-memory implementation of the \code{Checkpointer} interface. Stores
#' checkpoints in a dedicated R environment. This is useful for testing or
#' short-lived sessions where persistence to disk is not required.
#'
#' @importFrom R6 R6Class
#' @return A \code{MemorySaver} object.
#'
#' @examples
#' \dontrun{
#' saver <- MemorySaver$new()
#' dag <- dag_create(checkpointer = saver)
#'
#' # State is saved in saver$storage environment
#' }
#' @export
MemorySaver <- R6::R6Class("MemorySaver",
  inherit = Checkpointer,
  public = list(
    #' @field storage Environment. Stores the states.
    storage = NULL,

    #' @description Initialize MemorySaver
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
#' A lightweight, file-based checkpointer that uses R's native \code{saveRDS}
#' and \code{readRDS} functions. Each thread is saved as an individual \code{.rds}
#' file in a specified directory.
#'
#' @importFrom R6 R6Class
#' @return An \code{RDSSaver} object.
#'
#' @examples
#' \dontrun{
#' # Save checkpoints to a local directory
#' saver <- RDSSaver$new(dir = "my_checkpoints")
#'
#' # Later, resume execution using the same thread_id
#' dag <- dag_create(checkpointer = saver)
#' dag$run(thread_id = "session_001")
#' }
#' @export
RDSSaver <- R6::R6Class("RDSSaver",
  inherit = Checkpointer,
  public = list(
    #' @field dir String. Directory to store .rds checkpoint files.
    dir = NULL,

    #' @description Initialize RDSSaver
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
#' A production-grade \code{Checkpointer} that utilizes DuckDB for high-performance
#' state persistence. Supports BLOB storage of serialized R objects and
#' concurrent access patterns.
#'
#' @return A \code{DuckDBSaver} R6 object.
#'
#' @examples
#' \dontrun{
#' # Use a persistent DuckDB file for all agent states
#' saver <- DuckDBSaver$new(db_path = "data/hydrar_states.duckdb")
#'
#' dag <- dag_create(checkpointer = saver)
#' dag$run(thread_id = "batch_process_alpha")
#' }
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

    #' @description Initialize DuckDBSaver
    #' @param con DBIConnection.
    #' An existing DBI connection to a DuckDB instance.
    #' @param db_path String.
    #' Path to a DuckDB file. If provided, the driver will handle the
    #' connection internally.
    #' @param table_name String.
    #' The name of the table used to store checkpoints. Defaults to
    #' \code{"agent_checkpoints"}.
    initialize = function(con = NULL, db_path = NULL, table_name = "agent_checkpoints") {
      if (!is.character(table_name) || length(table_name) != 1 || !grepl("^[a-zA-Z0-9_]+$", table_name)) {
        stop("Invalid table_name: must be a single string containing only alphanumeric characters and underscores.")
      }
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
                        state_data BLOB,
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

      state_copy <- list(
        data = as.list(state$data),
        reducers = state$reducers,
        schema = state$schema
      )
      state_blob <- base::serialize(state_copy, NULL)

      # Upsert logic (DuckDB specific)
      DBI::dbExecute(self$con, sprintf("
                INSERT INTO %s (thread_id, state_data, updated_at)
                VALUES (?, ?, current_timestamp)
                ON CONFLICT (thread_id) DO UPDATE SET
                    state_data = excluded.state_data,
                    updated_at = excluded.updated_at
            ", self$table_name), params = list(thread_id, list(state_blob)))

      invisible(self)
    },

    #' Load state
    #' @param thread_id String.
    #' @return AgentState object or NULL.
    get = function(thread_id) {
      if (!is.character(thread_id) || length(thread_id) != 1) {
        stop("thread_id must be a single string.")
      }

      df <- DBI::dbGetQuery(self$con, sprintf("SELECT state_data FROM %s WHERE thread_id = ?", self$table_name), params = list(thread_id))

      if (nrow(df) > 0) {
        state_copy <- base::unserialize(df$state_data[[1]])
        # Re-hydrate AgentState
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

#' <!-- APAF Bioinformatics | checkpointer.R | Approved | 2026-03-29 -->

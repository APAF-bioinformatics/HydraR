# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        message_log.R
# Author:      APAF Agentic Workflow
# Purpose:     Communication Audit Logging
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Message Log Base R6 Class
#' @description Abstract base class for logging inter-agent messages.
#' @importFrom R6 R6Class
#' @export
MessageLog <- R6::R6Class("MessageLog",
  public = list(
    #' Log a message
    #' @param msg List. Message object.
    log = function(msg) {
      stop("Abstract method: log() must be implemented by subclass.")
    },
    #' Get all logs
    #' @return List of logs.
    get_all = function() {
      stop("Abstract method: get_all() must be implemented by subclass.")
    }
  )
)

#' Memory Message Log R6 Class
#' @description In-memory storage for messages.
#' @export
MemoryMessageLog <- R6::R6Class("MemoryMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field logs List.
    logs = list(),
    #' Log a message
    log = function(msg) {
      self$logs[[length(self$logs) + 1]] <- msg
      invisible(self)
    },
    #' Get all logs
    get_all = function() {
      self$logs
    }
  )
)

#' DuckDB Message Log R6 Class
#' @description Persists messages to the master DuckDB database.
#' @export
DuckDBMessageLog <- R6::R6Class("DuckDBMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field db_path String. Path to DuckDB file.
    db_path = NULL,
    #' Initialize DuckDBMessageLog
    #' @param db_path String.
    initialize = function(db_path = "~/.gemini/memory/bot_history.duckdb") {
      self$db_path <- path.expand(db_path)
    },
    #' Log a message
    log = function(msg) {
      # Use R/init_duckdb.R pattern if available, or direct DBI call.
      # Since we're keeping it portable, we use DBI directly.
      if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
        warning("DBI or duckdb not available. Skipping persistent log.")
        return(invisible(self))
      }
      
      con <- DBI::dbConnect(duckdb::duckdb(), self$db_path)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

      # Ensure table exists
      # Table schema: from, to, timestamp, content (json)
      DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS agent_messages (
          sender VARCHAR,
          recipient VARCHAR,
          timestamp TIMESTAMP,
          content_json JSON
        )
      ")

      # Prepare data for insertion
      df <- data.frame(
        sender = msg$from,
        recipient = msg$to,
        timestamp = as.POSIXct(msg$timestamp),
        content_json = jsonlite::toJSON(msg$content, auto_unbox = TRUE),
        stringsAsFactors = FALSE
      )

      DBI::dbWriteTable(con, "agent_messages", df, append = TRUE)
      invisible(self)
    },
    #' Get all logs
    get_all = function() {
      if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
        return(list())
      }
      con <- DBI::dbConnect(duckdb::duckdb(), self$db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
      
      if (!DBI::dbExistsTable(con, "agent_messages")) return(list())
      
      res <- DBI::dbReadTable(con, "agent_messages")
      # Convert back to list of objects
      lapply(seq_len(nrow(res)), function(i) {
        list(
          from = res$sender[i],
          to = res$recipient[i],
          timestamp = res$timestamp[i],
          content = jsonlite::fromJSON(res$content_json[i])
        )
      })
    }
  )
)

# <!-- APAF Bioinformatics | message_log.R | Approved | 2026-03-29 -->

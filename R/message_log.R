# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        message_log.R
# Author:      APAF Agentic Workflow
# Purpose:     Communication Audit Logging
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Message Log Base R6 Class
#'
#' @description Abstract base class for logging inter-agent messages.
#' @importFrom R6 R6Class
#' @export
MessageLog <- R6::R6Class("MessageLog",
  public = list(
    #' @description Store a message.
    #' @param msg List. Message object.
    #' @return The log object (invisibly).
    log = function(msg) {
      stop("Abstract method: log() must be implemented by subclass.")
    },
    #' @description Get all logs.
    #' @return List of logs.
    get_all = function() {
      stop("Abstract method: get_all() must be implemented by subclass.")
    }
  )
)

#' Memory Message Log R6 Class
#'
#' @description In-memory storage for messages.
#' @export
MemoryMessageLog <- R6::R6Class("MemoryMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field logs List. Storage for message logs.
    logs = list(),
    #' @description Store a message.
    #' @param msg List. Message object.
    #' @return The log object (invisibly).
    log = function(msg) {
      self$logs[[length(self$logs) + 1]] <- msg
      invisible(self)
    },
    #' @description Get all logs.
    #' @return List of logs.
    get_all = function() {
      self$logs
    }
  )
)

#' DuckDB Message Log R6 Class
#'
#' @description Persists messages to the master DuckDB database.
#' @export
DuckDBMessageLog <- R6::R6Class("DuckDBMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field db_path String. Path to DuckDB file.
    db_path = NULL,
    #' @field con DBIConnection. Cached DuckDB connection.
    con = NULL,
    #' @description Initialize DuckDBMessageLog.
    #' @param db_path String.
    #' @return A new `DuckDBMessageLog` object.
    initialize = function(db_path = "~/.gemini/memory/bot_history.duckdb") {
      self$db_path <- path.expand(db_path)
    },
    #' @description Store a message.
    #' @param msg List. Message object.
    #' @return The log object (invisibly).
    log = function(msg) {
      if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
        warning("DBI or duckdb not available. Skipping persistent log.")
        return(invisible(self))
      }

      if (is.null(self$con)) {
        self$con <- DBI::dbConnect(duckdb::duckdb(), self$db_path)
      }

      # Use tryCatch for JSON extension loading which might fail on restricted environments like CI
      tryCatch(
        {
          DBI::dbExecute(self$con, "INSTALL json")
          DBI::dbExecute(self$con, "LOAD json")
        },
        error = function(e) {
          # Silently ignore autoload failures in offline environments; duckdb might have it built-in or fall back safely
          NULL
        }
      )

      DBI::dbExecute(self$con, "
        CREATE TABLE IF NOT EXISTS agent_messages (
          sender VARCHAR,
          recipient VARCHAR,
          timestamp TIMESTAMP,
          content_json VARCHAR
        )
      ")

      df <- data.frame(
        sender = msg$from,
        recipient = msg$to,
        timestamp = as.POSIXct(msg$timestamp),
        content_json = jsonlite::toJSON(msg$content, auto_unbox = TRUE),
        stringsAsFactors = FALSE
      )

      DBI::dbWriteTable(self$con, "agent_messages", df, append = TRUE)
      invisible(self)
    },
    #' @description Get all logs.
    #' @return List of logs.
    get_all = function() {
      if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
        return(list())
      }

      if (is.null(self$con)) {
        self$con <- DBI::dbConnect(duckdb::duckdb(), self$db_path)
      }

      tryCatch(
        {
          DBI::dbExecute(self$con, "INSTALL json")
          DBI::dbExecute(self$con, "LOAD json")
        },
        error = function(e) NULL
      )

      if (!DBI::dbExistsTable(self$con, "agent_messages")) {
        return(list())
      }

      res <- DBI::dbReadTable(self$con, "agent_messages")
      lapply(seq_len(nrow(res)), function(i) {
        list(
          from = res$sender[i],
          to = res$recipient[i],
          timestamp = res$timestamp[i],
          content = jsonlite::fromJSON(res$content_json[i])
        )
      })
    }
  ),
  private = list(
    #' @description Finalizer to clean up the cached connection.
    finalize = function() {
      if (!is.null(self$con) && requireNamespace("DBI", quietly = TRUE)) {
        try(DBI::dbDisconnect(self$con, shutdown = TRUE), silent = TRUE)
      }
    }
  )
)

#' JSONL Message Log R6 Class
#'
#' @description Persists messages to a JSON Lines file. Atomic file appending
#' ensures that multiple parallel worktree processes can log messages
#' without locking conflicts.
#' @export
JSONLMessageLog <- R6::R6Class("JSONLMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field path String. Path to JSONL file.
    path = NULL,
    #' @description Initialize JSONLMessageLog.
    #' @param path String.
    initialize = function(path = tempfile(fileext = ".jsonl")) {
      self$path <- path
    },
    #' @description Store a message (atomic append).
    #' @param msg List. Message object.
    log = function(msg) {
      # Use base::cat with append=TRUE for simple, atomic-like writes on Unix
      line <- jsonlite::toJSON(msg, auto_unbox = TRUE)
      cat(paste0(line, "\n"), file = self$path, append = TRUE)
      invisible(self)
    },
    #' @description Get all logs.
    #' @return List of logs.
    get_all = function() {
      if (!file.exists(self$path)) {
        return(list())
      }
      lines <- readLines(self$path, warn = FALSE)
      lapply(lines, jsonlite::fromJSON)
    }
  )
)

# <!-- APAF Bioinformatics | message_log.R | Approved | 2026-03-30 -->

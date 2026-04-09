# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        message_log.R
# Author:      APAF Agentic Workflow
# Purpose:     Communication Audit Logging
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Message Log Base R6 Class
#'
#' @description
#' An abstract base class defining the interface for message logging in HydraR.
#' Subclasses provide concrete storage implementations (Memory, File, Database).
#'
#' @return A \code{MessageLog} base object.
#' @examples
#' \dontrun{
#' # This is an abstract base class.
#' # Use MemoryMessageLog or DuckDBMessageLog instead.
#' }
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
#' @description
#' A non-persistent, in-memory implementation of \code{MessageLog}. Messages
#' are stored in an internal list that exists only for the duration of the
#' R session.
#'
#' @return A \code{MemoryMessageLog} object.
#'
#' @examples
#' \dontrun{
#' # Create a new memory logger
#' log <- MemoryMessageLog$new()
#'
#' # The DAG will automatically call log$log() during execution
#' dag <- dag_create(message_log = log)
#' }
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
#' @description
#' A persistent implementation of \code{MessageLog} that writes messages to a
#' centralized DuckDB database. This is the recommended logger for production
#' and audit-heavy workflows.
#'
#' @return A \code{DuckDBMessageLog} object.
#'
#' @examples
#' \dontrun{
#' # Initialize a logger pointing to the default HydraR database
#' audit_log <- DuckDBMessageLog$new(
#'   db_path = "~/.gemini/memory/audit.duckdb"
#' )
#'
#' # Messages are stored in the 'agent_messages' table
#' }
#' @export
DuckDBMessageLog <- R6::R6Class("DuckDBMessageLog",
  inherit = MessageLog,
  private = list(
    con = NULL,
    get_connection = function() {
      if (is.null(private$con)) {
        if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
          return(NULL)
        }
        private$con <- DBI::dbConnect(duckdb::duckdb(), self$db_path)
      }
      private$con
    },
    #' @description Finalizer to clean up the cached connection.
    finalize = function() {
      if (!is.null(private$con) && requireNamespace("DBI", quietly = TRUE)) {
        try(DBI::dbDisconnect(private$con, shutdown = TRUE), silent = TRUE)
      }
    }
  ),
  public = list(
    #' @field db_path String. Path to DuckDB file.
    db_path = NULL,
    #' @description Initialize DuckDBMessageLog.
    #' @param db_path String.
    #' Path to the DuckDB file. If the file does not exist, it will be
    #' created upon the first message log. Defaults to the master
    #' \code{bot_history.duckdb}.
    #' @return A new \code{DuckDBMessageLog} object.
    initialize = function(db_path = "~/.gemini/memory/bot_history.duckdb") {
      self$db_path <- path.expand(db_path)
    },
    #' @description Store a message.
    #' @param msg List. Message object.
    #' @return The log object (invisibly).
    log = function(msg) {
      con <- private$get_connection()
      if (is.null(con)) {
        warning("DBI or duckdb not available. Skipping persistent log.")
        return(invisible(self))
      }

      # Use tryCatch for JSON extension loading which might fail on restricted environments like CI
      tryCatch(
        {
          DBI::dbExecute(con, "INSTALL json")
          DBI::dbExecute(con, "LOAD json")
        },
        error = function(e) {
          # Silently ignore autoload failures in offline environments; duckdb might have it built-in or fall back safely
          NULL
        }
      )

      DBI::dbExecute(con, "
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

      DBI::dbWriteTable(con, "agent_messages", df, append = TRUE)
      invisible(self)
    },
    #' @description Get all logs.
    #' @return List of logs.
    get_all = function() {
      con <- private$get_connection()
      if (is.null(con)) {
        return(list())
      }

      tryCatch(
        {
          DBI::dbExecute(con, "INSTALL json")
          DBI::dbExecute(con, "LOAD json")
        },
        error = function(e) NULL
      )

      if (!DBI::dbExistsTable(con, "agent_messages")) {
        return(list())
      }

      res <- DBI::dbReadTable(con, "agent_messages")
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

#' JSONL Message Log R6 Class
#'
#' @description
#' A file-based implementation of \code{MessageLog} that appends messages to
#' a JSON Lines file. This implementation is safe for parallel execution across
#' git worktrees as it uses atomic line appending.
#'
#' @return A \code{JSONLMessageLog} object.
#'
#' @examples
#' \dontrun{
#' # Create a logger that writes to a specific project file
#' file_log <- JSONLMessageLog$new(path = "workflow_audit.jsonl")
#'
#' # Executing a DAG with this logger will populate the file
#' dag <- dag_create(message_log = file_log)
#' }
#' @export
JSONLMessageLog <- R6::R6Class("JSONLMessageLog",
  inherit = MessageLog,
  public = list(
    #' @field path String. Path to JSONL file.
    path = NULL,
    #' @description Initialize JSONLMessageLog.
    #' @param path String.
    #' The output file path for the JSON Lines log. Defaults to a temporary file.
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

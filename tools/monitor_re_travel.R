# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        monitor_re_travel.R
# Purpose:     Monitor DuckDB Progress and State (Robust Printing)
# ==============================================================

library(DBI)
library(duckdb)

db_file <- "vignettes/travel_booking.duckdb"
temp_db <- "travel_booking_peek.duckdb"

# Function to monitor progress
monitor_progress <- function() {
  if (!file.exists(db_file)) {
    message("Waiting for travel_booking.duckdb to be created...")
    return()
  }

  cat(sprintf("[%s] [System] Source DB: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), normalizePath(db_file)))
  
  # Copy BOTH the main file AND the WAL file
  file.copy(db_file, temp_db, overwrite = TRUE)
  if (file.exists(paste0(db_file, ".wal"))) {
    file.copy(paste0(db_file, ".wal"), paste0(temp_db, ".wal"), overwrite = TRUE)
  }
  
  con <- tryCatch({
    dbConnect(duckdb::duckdb(), temp_db, read_only = TRUE)
  }, error = function(e) {
    message("Error connecting to copy: ", e$message)
    return(NULL)
  })
  
  if (is.null(con)) return()
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  on.exit(file.remove(temp_db), add = TRUE)
  if (file.exists(paste0(temp_db, ".wal"))) on.exit(file.remove(paste0(temp_db, ".wal")), add = TRUE)

  tables <- dbListTables(con)

  if ("agent_checkpoints" %in% tables) {
    checkpoint <- dbGetQuery(con, "SELECT thread_id, state_data, CAST(updated_at AS VARCHAR) as ts FROM agent_checkpoints ORDER BY updated_at DESC LIMIT 1")
    
    if (nrow(checkpoint) > 0) {
      cat(sprintf("\n=== LATEST CHECKPOINT (Thread: %s) ===\n", checkpoint$thread_id))
      cat("Updated at: ", checkpoint$ts, "\n")
      
      state_list <- unserialize(checkpoint$state_data[[1]])
      
      # 1. Trace log
      trace_log <- state_list$data$`__trace_log__`
      if (!is.null(trace_log) && length(trace_log) > 0) {
        cat("\n--- Execution Trace (Last 5) ---\n")
        trace_log <- trace_log[!vapply(trace_log, is.null, logical(1))]
        n <- length(trace_log)
        last_indices <- seq(max(1, n - 4), n)
        
        purrr::walk(trace_log[last_indices], \(step) {
          cat(sprintf("[%s] Step %d: Node=%s, Status=%s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), step$step, step$node, step$status))
        })
      }

      # 2. Validation Report
      report <- state_list$data$report
      if (!is.null(report)) {
        cat("\n--- Latest Validation Report ---\n")
        cat(as.character(report), "\n")
      }
    } else {
      cat("Checkpoint table is empty.\n")
    }
  } else {
    cat("agent_checkpoints table not found in copy.\n")
  }
}

monitor_progress()

# <!-- APAF Bioinformatics | monitor_re_travel.R | Approved | 2026-04-03 -->

library(DBI)
library(duckdb)

# Copy the DB to avoid locking issues while peek
temp_db <- "travel_booking_debug.duckdb"
if (file.exists("travel_booking.duckdb")) {
  file.copy("travel_booking.duckdb", temp_db, overwrite = TRUE)
  con <- dbConnect(duckdb::duckdb(), temp_db, read_only = TRUE)
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  on.exit(file.remove(temp_db), add = TRUE)

  # 1. Check the trace table
  if (dbExistsTable(con, "trace")) {
    cat("\n=== DAG TRACE LOG (Last 10 steps) ===\n")
    trace_log <- dbGetQuery(con, "SELECT id, node_id, status, CAST(timestamp AS VARCHAR) as ts FROM trace ORDER BY id DESC LIMIT 10")
    print(trace_log)
  }

  # 2. Check the latest checkpoint
  if (dbExistsTable(con, "agent_checkpoints")) {
    cat("\n=== LATEST CHECKPOINT STATE ===\n")
    checkpoint <- dbGetQuery(con, "SELECT node_id, CAST(timestamp AS VARCHAR) as ts, state_data FROM agent_checkpoints ORDER BY id DESC LIMIT 1")
    if (nrow(checkpoint) > 0) {
      cat("Last Node:", checkpoint$node_id, "at", checkpoint$ts, "\n")
      state_list <- unserialize(checkpoint$state_data[[1]])
      cat("Available Keys in State:\n")
      print(names(state_list$data))
      
      # Check if ImageGenerator actually finished and where it thought it was saving
      if ("image_prompts" %in% names(state_list$data)) {
        cat("\nGenerated Image Prompts Found.\n")
      }
    }
  }
} else {
  cat("travel_booking.duckdb not found in current directory.\n")
}

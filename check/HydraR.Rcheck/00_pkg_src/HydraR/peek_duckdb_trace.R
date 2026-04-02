# Peek at locked DuckDB by copying it first
temp_db <- "vignettes/travel_booking_peek.duckdb"
file.copy("vignettes/travel_booking.duckdb", temp_db, overwrite = TRUE)

con <- DBI::dbConnect(duckdb::duckdb(), temp_db, read_only = TRUE)
tables <- DBI::dbListTables(con)

if ("agent_checkpoints" %in% tables) {
  res <- DBI::dbGetQuery(con, "SELECT state_data FROM agent_checkpoints LIMIT 1")
  if(nrow(res) > 0) {
    # HydraR saves state_data as a BLOB (raw vector)
    blob <- res$state_data[[1]]
    # It is a serialized list containing 'data' (environment)
    state_list <- unserialize(blob)
    
    # Trace log is usually stored in the 'data' list under '__trace_log__'
    trace <- state_list$data[["__trace_log__"]]
    
    if (!is.null(trace)) {
      cat("Trace length: ", length(trace), "\n")
      for(i in seq_along(trace)) {
        node_info <- trace[[i]]
        cat(sprintf("[%d] %s (status: %s)\n", i, node_info$node, node_info$status))
      }
    } else {
      cat("No trace log found in state checkpoints.\n")
    }
  } else {
    cat("Table agent_checkpoints is empty.\n")
  }
} else {
  cat("Table 'agent_checkpoints' not found. Tables: ", paste(tables, collapse=", "), "\n")
}

DBI::dbDisconnect(con)
file.remove(temp_db)

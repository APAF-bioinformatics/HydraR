con <- DBI::dbConnect(duckdb::duckdb(), "vignettes/travel_booking.duckdb", read_only = TRUE)
res <- DBI::dbGetQuery(con, "SELECT * FROM agent_checkpoints")
if(nrow(res)>0) {
  blob <- res$state_blob[[1]]
  state <- unserialize(blob)
  trace <- state$get("__trace_log__")
  cat("Trace length: ", length(trace), "\n")
  for(i in seq_along(trace)) {
    cat(sprintf("[%d] %s (mode: %s, status: %s)\n", i, trace[[i]]$node, trace[[i]]$mode, trace[[i]]$status))
  }
} else {
  cat("No checkpoints found.\n")
}
DBI::dbDisconnect(con)

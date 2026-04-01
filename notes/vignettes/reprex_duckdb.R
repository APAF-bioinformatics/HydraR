## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----lib_load-----------------------------------------------------------------
library(HydraR)
db_path <- tempfile(fileext = ".duckdb")

## ----register_logic-----------------------------------------------------------
register_logic("init_proc", function(state) {
  list(status = "success", output = "Initialization complete.")
})

register_logic("check_fixed", function(state) {
  if (!isTRUE(state$get("fixed"))) {
    # Return "pause" status — HydraR saves state and stops cleanly
    return(list(status = "pause", output = "Waiting for manual fix."))
  }
  list(status = "success", output = "System recovered!")
})

register_logic("finalize_proc", function(state) {
  list(status = "success", output = "All steps finished.")
})

## ----build_dag----------------------------------------------------------------
mermaid_src <- '
graph TD
  Step1["Initialization | type=logic | logic_id=init_proc"]
  Step2["Risky Logic | type=logic | logic_id=check_fixed"]
  Step3["Conclusion | type=logic | logic_id=finalize_proc"]
  Step1 --> Step2
  Step2 --> Step3
'

dag <- mermaid_to_dag(mermaid_src)
dag$set_start_node("Step1")

## ----run_1--------------------------------------------------------------------
# Configure DuckDB Persistence
saver <- DuckDBSaver$new(db_path = db_path)
tid <- "reprex-session-001"

# Run 1: Expected to pause at Step2
res1 <- dag$run(
  thread_id = tid,
  checkpointer = saver,
  initial_state = list(fixed = FALSE, counter = 0)
)

cat("Execution Status:", res1$status, "\n")
cat("Paused at:", res1$paused_at, "\n")

## ----inspect------------------------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), db_path)
DBI::dbGetQuery(con, "SELECT thread_id, updated_at FROM agent_checkpoints")
DBI::dbDisconnect(con, shutdown = TRUE)

## ----run_2--------------------------------------------------------------------
# Fixing the state: Set 'fixed' to TRUE
new_state <- list(fixed = TRUE)

# Run 2: Resume from Step2 using the SAME thread_id
final_results <- dag$run(
  thread_id = tid,
  checkpointer = saver,
  initial_state = new_state,
  resume_from = "Step2"
)

# Verify results
cat("Final Status:", final_results$status, "\n")
cat("Step2 Output:", final_results$results$Step2$output, "\n")
cat("Step3 Output:", final_results$results$Step3$output, "\n")


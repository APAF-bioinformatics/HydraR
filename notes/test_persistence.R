library(HydraR)
wf <- load_workflow("vignettes/state_persistence.yml")
dag <- spawn_dag(wf, auto_node_factory())

# Configure DuckDB Persistence
db_p <- "notes/history.duckdb"
if (file.exists(db_p)) unlink(db_p)
saver <- DuckDBSaver$new(db_path = db_p)
tid <- "session-001"

# Run 1: Pause at Step2
message("--- Run 1 (Expect Pause) ---")
res1 <- dag$run(
  thread_id = tid,
  checkpointer = saver,
  initial_state = list(fixed = FALSE)
)
message("Status 1: ", res1$status)

# Run 2: Resume from Step2
message("--- Run 2 (Expect Success) ---")
res2 <- dag$run(
  thread_id = tid,
  checkpointer = saver,
  initial_state = list(fixed = TRUE),
  resume_from = "Step2"
)
message("Status 2: ", res2$status)

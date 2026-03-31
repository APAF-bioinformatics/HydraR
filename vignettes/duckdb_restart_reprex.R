# Agentic Checkpointing and Restarts with DuckDB
#
# In the Journal of Open Source Software (JOSS), computational reproducibility is paramount.
# `HydraR` enables robust scientific pipelines that can pause, halt on errors, and be cleanly
# restarted without losing context.
#
# This script provides a minimal reproducible example (reprex) of how to use `DuckDBSaver`
# to persist agent state, simulate a failure, fix the underlying logic, and restart
# the execution seamlessly from the point of failure.

library(HydraR)
library(duckdb)

# Setup the Checkpointer
db_path <- tempfile(fileext = ".duckdb")
checkpointer <- DuckDBSaver$new(db_path = db_path)
thread_id <- "reprex_run_001"

# Define the Workflow
# Node A: A successful, expensive initial step
node_a <- AgentLogicNode$new(
  id = "Data_Prep",
  logic_fn = function(state) {
    message("Running expensive data preparation...")
    # Simulate work
    Sys.sleep(1)
    list(status = "SUCCESS", output = list(prep_done = TRUE, data = c(1, 2, 3)))
  }
)

# Node B: Initially buggy analysis step
node_b_buggy <- AgentLogicNode$new(
  id = "Analysis",
  logic_fn = function(state) {
    data <- state$get("Data_Prep")$data
    message("Running analysis...")
    # INTENTIONAL BUG: trying to sum a NULL value if data wasn't handled correctly
    stop("Simulated crash: unexpected data format in Analysis!")
  }
)

dag <- AgentDAG$new()
dag$add_node(node_a)
dag$add_node(node_b_buggy)
dag$add_edge("Data_Prep", "Analysis")
dag$compile()

# First Run: Catching the Failure
tryCatch(
  {
    dag$run(
      initial_state = list(input = "Start"),
      checkpointer = checkpointer,
      thread_id = thread_id
    )
  },
  error = function(e) {
    message("DAG execution failed as expected: ", e$message)
  }
)

# At this point, the state after `Data_Prep` is safely stored in DuckDB.
# We can retrieve it to inspect the context at the time of failure.
saved_state <- checkpointer$get(thread_id)
print(saved_state$get("Data_Prep"))

# The Fix & Restart
# Now, we "fix" the bug in Node B and create a new DAG.
node_b_fixed <- AgentLogicNode$new(
  id = "Analysis",
  logic_fn = function(state) {
    data <- state$get("Data_Prep")$data
    message("Running FIXED analysis...")
    list(status = "SUCCESS", output = list(result = sum(data)))
  }
)

# Rebuild DAG with fixed node
fixed_dag <- AgentDAG$new()
fixed_dag$add_node(node_a)
fixed_dag$add_node(node_b_fixed)
fixed_dag$add_edge("Data_Prep", "Analysis")
fixed_dag$compile()

# Restart from DuckDB checkpoint
message("Restarting from checkpoint...")
restarted_result <- fixed_dag$run(
  initial_state = checkpointer$get(thread_id),
  resume_from = "Analysis",
  checkpointer = checkpointer,
  thread_id = thread_id
)

message("Final Result: ", restarted_result$state$get("Analysis")$result)

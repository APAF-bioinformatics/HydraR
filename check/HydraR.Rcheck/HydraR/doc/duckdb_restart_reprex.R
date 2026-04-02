## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----checkpointer_setup, eval=FALSE-------------------------------------------
# library(HydraR)
# library(duckdb)
# 
# db_path <- tempfile(fileext = ".duckdb")
# checkpointer <- DuckDBSaver$new(db_path = db_path)
# thread_id <- "reprex_run_001"

## ----logic_nodes, eval=FALSE--------------------------------------------------
# # Node A: A successful, expensive initial step
# node_a <- AgentLogicNode$new(
#   id = "Data_Prep",
#   logic_fn = function(state) {
#     message("Running expensive data preparation...")
#     # Simulate work
#     Sys.sleep(1)
#     list(status = "SUCCESS", output = list(prep_done = TRUE, data = c(1, 2, 3)))
#   }
# )
# 
# # Node B: Initially buggy analysis step
# node_b_buggy <- AgentLogicNode$new(
#   id = "Analysis",
#   logic_fn = function(state) {
#     data <- state$get("Data_Prep")$data
#     message("Running analysis...")
#     # INTENTIONAL BUG: trying to sum a NULL value if data wasn't handled correctly
#     stop("Simulated crash: unexpected data format in Analysis!")
#   }
# )
# 
# dag <- AgentDAG$new()
# dag$add_node(node_a)
# dag$add_node(node_b_buggy)
# dag$add_edge("Data_Prep", "Analysis")
# dag$compile()

## ----first_run, eval=FALSE, error=TRUE----------------------------------------
try({
# tryCatch(
#   {
#     dag$run(
#       initial_state = list(input = "Start"),
#       checkpointer = checkpointer,
#       thread_id = thread_id
#     )
#   },
#   error = function(e) {
#     message("DAG execution failed as expected: ", e$message)
#   }
# )
})

## ----inspect_state, eval=FALSE------------------------------------------------
# saved_state <- checkpointer$get(thread_id)
# print(saved_state$get("Data_Prep"))
# # $prep_done
# # [1] TRUE
# # $data
# # [1] 1 2 3

## ----restart, eval=FALSE------------------------------------------------------
# # Fix the logic
# node_b_fixed <- AgentLogicNode$new(
#   id = "Analysis",
#   logic_fn = function(state) {
#     data <- state$get("Data_Prep")$data
#     message("Running FIXED analysis...")
#     list(status = "SUCCESS", output = list(result = sum(data)))
#   }
# )
# 
# # Rebuild DAG with fixed node
# fixed_dag <- AgentDAG$new()
# fixed_dag$add_node(node_a)
# fixed_dag$add_node(node_b_fixed)
# fixed_dag$add_edge("Data_Prep", "Analysis")
# fixed_dag$compile()
# 
# # Restart from DuckDB checkpoint
# message("Restarting from checkpoint...")
# restarted_result <- fixed_dag$run(
#   initial_state = checkpointer$get(thread_id),
#   resume_from = "Analysis",
#   checkpointer = checkpointer,
#   thread_id = thread_id
# )
# 
# message("Final Result: ", restarted_result$state$get("Analysis")$result)
# # Output should be: Final Result: 6


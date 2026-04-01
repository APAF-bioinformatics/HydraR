## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)

## ----setup--------------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
hello_logic_registry <- list(
  # 0. Initial Configuration
  initial_state = list(
    input = "hello hydra"
  ),

  # 1. Deterministic Logic Functions
  logic = list(
    collect_input = function(state, params = NULL) {
      list(status = "SUCCESS", output = list(input_raw = state$get("input")))
    },
    process_data = function(state, params = NULL) {
      raw <- state$get("input_raw")
      res <- paste0("HYDRAR says: ", toupper(raw))
      list(status = "SUCCESS", output = list(processed_result = res))
    }
  )
)

## ----factory------------------------------------------------------------------
hello_node_factory <- function(id, label, params) {
  AgentLogicNode$new(
    id = id,
    label = label,
    logic_fn = hello_logic_registry$logic[[id]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  collect_input[Collect Input] --> process_data[Process Data]
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = hello_node_factory)
compiled_dag <- dag$compile()

## ----running------------------------------------------------------------------
checkpointer <- MemorySaver$new()
thread_id <- "hello_test_run"

final <- compiled_dag$run(
  initial_state = hello_logic_registry$initial_state,
  checkpointer = checkpointer,
  thread_id = thread_id
)

print(final$results$process_data$output$processed_result)

## ----restore------------------------------------------------------------------
restored <- checkpointer$get(thread_id)
print(restored$get("processed_result"))


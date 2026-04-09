# Hello World Logic Nodes

This vignette provides a basic “Hello World” example of `HydraR` logic
nodes, demonstrating simple data processing and state persistence.

## Setup

``` r
library(HydraR)
```

## Defining the Workflow Components

To keep our architecture clean, we store all deterministic logic
functions and the initial configuration in a central registry.

``` r
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
```

## The Node Factory

We use a factory function to dynamically create nodes based on their IDs
defined in the Mermaid graph.

``` r
hello_node_factory <- function(id, label, params) {
  AgentLogicNode$new(
    id = id,
    label = label,
    logic_fn = hello_logic_registry$logic[[id]]
  )
}
```

## Building the DAG via Mermaid

We define the entire workflow architecture as a Mermaid string. This
string serves as the single source of truth for both structure and node
metadata.

``` r
mermaid_graph <- "
graph TD
  collect_input[Collect Input] --> process_data[Process Data]
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = hello_node_factory)
compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Running with the Checkpointer

We use a `MemorySaver` to persist the state throughout the run.

``` r
checkpointer <- MemorySaver$new()
thread_id <- "hello_test_run"

final <- compiled_dag$run(
  initial_state = hello_logic_registry$initial_state,
  checkpointer = checkpointer,
  thread_id = thread_id
)
#> Graph compiled successfully.
#> [Linear] Running Node: collect_input
#>    [collect_input] Executing R logic...
#> [Linear] Running Node: process_data
#>    [process_data] Executing R logic...

print(final$results$process_data$output$processed_result)
#> [1] "HYDRAR says: HELLO HYDRA"
```

## Verifying Checkpoint Restoration

The `Checkpointer` allows us to verify the final state.

``` r
restored <- checkpointer$get(thread_id)
print(restored$get("processed_result"))
#> [1] "HYDRAR says: HELLO HYDRA"
```

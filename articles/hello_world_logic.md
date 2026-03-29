# Hello World Logic Nodes

This vignette provides a basic “Hello World” example of `HydraR` logic
nodes, demonstrating simple data processing and state persistence.

## Setup

``` r
library(HydraR)
```

## Defining Logic Nodes

Logic nodes perform computation on the project state. We define two: one
to collect input and another to transform it.

``` r
# 1. Collect Input Node
node_input <- AgentLogicNode$new(
  id = "collect_input",
  logic_fn = function(state) {
    list(status = "SUCCESS", output = list(input_raw = state$get("input")))
  }
)

# 2. Process Data Node
node_process <- AgentLogicNode$new(
  id = "process_data",
  logic_fn = function(state) {
    raw <- state$get("input_raw")
    res <- paste0("HYDRAR says: ", toupper(raw))
    list(status = "SUCCESS", output = list(processed_result = res))
  }
)
```

## Assembling the DAG

Next, we add these nodes to an `AgentDAG` and connect them.

``` r
dag <- AgentDAG$new()
dag$add_node(node_input)
dag$add_node(node_process)
dag$add_edge("collect_input", "process_data")
dag$compile()
#> Graph compiled successfully.
```

## Running with the Checkpointer

We use a `MemorySaver` to persist the state throughout the run.

``` r
checkpointer <- MemorySaver$new()
thread_id <- "hello_test_run"

final <- dag$run(
  initial_state = list(input = "hello hydra"),
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

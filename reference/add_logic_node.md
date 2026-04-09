# Create an R Logic Node

A convenience wrapper to instantiate an `AgentLogicNode`. Nodes created
this way execute pure R code rather than calling an LLM.

## Usage

``` r
add_logic_node(id, logic_fn, ...)
```

## Arguments

- id:

  String. A unique identifier for the node.

- logic_fn:

  Function. An R function that accepts an `AgentState` object as its
  first argument and returns a list with at least `status` and `output`.

- ...:

  Additional arguments. Passed directly to the `AgentLogicNode$new()`
  constructor.

## Value

An `AgentLogicNode` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Define a logic function that validates a previous node's output
validator <- function(state) {
  raw_data <- state$get("data_fetcher")
  if (length(raw_data) > 0) {
    list(status = "success", output = list(valid = TRUE))
  } else {
    list(status = "failed", output = list(valid = FALSE))
  }
}

node <- add_logic_node("data_validator", validator)
} # }
```

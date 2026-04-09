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
# 1. Validation Logic: Check if previous output meets quality thresholds
quality_gate <- function(state) {
  results <- state$get("researcher")
  if (length(results$papers) >= 5) {
    list(status = "success", output = list(proceed = TRUE))
  } else {
    # 'pause' status can trigger a human-in-the-loop or a retry loop
    list(status = "pause", output = list(reason = "insufficient results"))
  }
}
node_gate <- add_logic_node("quality_gate", quality_gate)

# 2. Data Transformation Logic: Clean and format LLM output
cleaner <- function(state) {
  raw_text <- state$get("coder")
  clean_code <- extract_r_code_advanced(raw_text)
  list(status = "success", output = list(code = clean_code))
}
node_clean <- add_logic_node("cleaner", cleaner)
} # }
```

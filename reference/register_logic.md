# Register Logic Function

Stores a pure R function in a centralized logic registry. This allows
the function to be referenced by name in Mermaid diagrams or YAML/JSON
workflow definitions without needing to pass the function object across
environments.

## Usage

``` r
register_logic(name, fn)
```

## Arguments

- name:

  String. A unique identifier for the function (e.g.,
  `"validate_data"`).

- fn:

  Function. The R function to be registered. It should typically accept
  an `AgentState` or `RestrictedState` object.

## Value

The registry environment (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Register a simple math function
register_logic("add_one", function(state) list(status="ok", output=state$get("x")+1))

# 2. Register a complex validation function that uses the Logic Registry
# This function can now be referenced by name 'validate_results' in any YAML workflow.
validate_results <- function(state) {
  results <- state$get("researcher_node")
  if (is.null(results)) return(list(status = "failed", message = "No results found"))
  list(status = "success", output = list(valid = TRUE))
}
register_logic("validate_results", validate_results)
} # }
```

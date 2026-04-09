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
# Register a logic function for use in a DAG
my_fn <- function(state) {
  input <- state$get("raw_input")
  list(status = "success", output = nchar(input))
}
register_logic("calculate_length", my_fn)
} # }
```

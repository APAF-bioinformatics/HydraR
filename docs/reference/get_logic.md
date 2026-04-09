# Get Logic Function

Get Logic Function

## Usage

``` r
get_logic(name)
```

## Arguments

- name:

  String. Unique identifier.

## Value

Function or NULL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve a function by name for manual node construction
logic_fn <- get_logic("validate_results")
if (!is.null(logic_fn)) {
  node <- AgentLogicNode$new(id = "validator", logic_fn = logic_fn)
}
} # }
```

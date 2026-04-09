# Built-in Reducer: Append

A functional reducer that appends new elements to an existing vector or
list. This is the standard pattern for accumulating results or logs
across multiple agent steps.

## Usage

``` r
reducer_append(current, new)
```

## Arguments

- current:

  The current value in the state.

- new:

  The new value to be added.

## Value

A combined vector or list containing both `current` and `new`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Used in AgentState initialization
state <- AgentState$new(
  initial_data = list(logs = list()),
  reducers = list(logs = reducer_append)
)
} # }
```

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
# Accumulate a trace of agent IDs
state <- AgentState$new(
  initial_data = list(visited = character()),
  reducers = list(visited = reducer_append)
)

state$update(list(visited = "agent_a"))
state$update(list(visited = "agent_b"))

print(state$get("visited")) # [1] "agent_a" "agent_b"
} # }
```

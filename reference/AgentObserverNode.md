# Agent Observer Node R6 Class

A node that executes logic for side-effects (e.g., logging,
notifications). Its output does not modify the primary AgentState.

## Value

An \`AgentObserverNode\` object.

## Super class

[`HydraR::AgentNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentNode.md)
-\> `AgentObserverNode`

## Public fields

- `observe_fn`:

  Function(state) -\> void.

## Methods

### Public methods

- [`AgentObserverNode$new()`](#method-AgentObserverNode-new)

- [`AgentObserverNode$run()`](#method-AgentObserverNode-run)

- [`AgentObserverNode$clone()`](#method-AgentObserverNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentObserverNode

#### Usage

    AgentObserverNode$new(id, observe_fn, label = NULL, params = list())

#### Arguments

- `id`:

  Unique identifier.

- `observe_fn`:

  Function that takes an AgentState.

- `label`:

  Optional label.

- `params`:

  Optional parameters. Run the Observer Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentObserverNode$run(state, ...)

#### Arguments

- `state`:

  AgentState or RestrictedState object.

- `...`:

  Additional arguments.

#### Returns

List with status "observer" and NULL output.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentObserverNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# An observer that logs stats to a file without modifying state
logger <- function(state) {
  stats <- state$get_all()
  writeLines(jsonlite::toJSON(stats), "logs/observation.json")
  message("Stats observed and written to logs.")
}

node_obs <- AgentObserverNode$new(
  id = "status_logger",
  observe_fn = logger
)

# Run with dummy state
node_obs$run(AgentState$new(list(x = 10, y = 20)))
} # }
```

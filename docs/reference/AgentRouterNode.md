# Agent Router Node R6 Class

A node that determines the next node in the DAG dynamically. The logic
function must return a list with a \`target_node\` field.

## Value

An \`AgentRouterNode\` object.

## Super class

[`HydraR::AgentNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentNode.md)
-\> `AgentRouterNode`

## Public fields

- `router_fn`:

  Function(state) -\> List(target_node, output).

## Methods

### Public methods

- [`AgentRouterNode$new()`](#method-AgentRouterNode-new)

- [`AgentRouterNode$run()`](#method-AgentRouterNode-run)

- [`AgentRouterNode$clone()`](#method-AgentRouterNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentRouterNode

#### Usage

    AgentRouterNode$new(id, router_fn, label = NULL, params = list())

#### Arguments

- `id`:

  Unique identifier.

- `router_fn`:

  Function that takes an AgentState and returns a list.

- `label`:

  Optional human-readable name.

- `params`:

  Optional list of parameters. Run the Router Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentRouterNode$run(state, ...)

#### Arguments

- `state`:

  AgentState object.

- `...`:

  Additional arguments.

#### Returns

List with status, output, and target_node.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentRouterNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Routing based on an LLM sentiment classification
classifier <- function(state) {
  sentiment <- state$get("analyst_output")
  if (grepl("Positive", sentiment)) {
    list(target_node = "celebrate", status = "success")
  } else {
    list(target_node = "investigate", status = "success")
  }
}

node_router <- AgentRouterNode$new(
  id = "sentiment_router",
  router_fn = classifier
)

# Run with dummy state
res <- node_router$run(AgentState$new(list(analyst_output = "Positive results!")))
message("Targeting node: ", res$target_node)
} # }
```

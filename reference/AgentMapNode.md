# Agent Map Node R6 Class

A node that maps over a list in the state and performs an operation.

## Value

An \`AgentMapNode\` object.

## Super class

[`HydraR::AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
-\> `AgentMapNode`

## Public fields

- `map_key`:

  String. Key in state to map over.

- `logic_fn`:

  Function(item, state) -\> List(status, output).

## Methods

### Public methods

- [`AgentMapNode$new()`](#method-AgentMapNode-new)

- [`AgentMapNode$run()`](#method-AgentMapNode-run)

- [`AgentMapNode$clone()`](#method-AgentMapNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentMapNode

#### Usage

    AgentMapNode$new(id, map_key, logic_fn, label = NULL, params = list())

#### Arguments

- `id`:

  Unique identifier.

- `map_key`:

  String identifier for state retrieval.

- `logic_fn`:

  Mapping function.

- `label`:

  Optional label.

- `params`:

  Optional parameters. Run the Map Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentMapNode$run(state, ...)

#### Arguments

- `state`:

  AgentState object.

- `...`:

  Additional arguments.

#### Returns

List with status, output (list of results).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentMapNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Mapping over a list of URLs to fetch data
fetch_logic <- function(url, state) {
  # Custom logic for each item
  list(status = "success", output = paste0("Data from ", url))
}

node_map <- AgentMapNode$new(
  id = "batch_fetcher",
  map_key = "url_list",
  logic_fn = fetch_logic
)

# Setup state with items to map over
state <- AgentState$new(list(url_list = c("url1", "url2", "url3")))
results <- node_map$run(state)
} # }
```

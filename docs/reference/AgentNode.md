# Agent Node Base Class

The abstract base R6 class for all nodes within an `AgentDAG`. It
defines the common interface and fields required for any node to be
orchestrated by the HydraR engine. Subclasses must implement the `run()`
method.

## Value

An `AgentNode` object.

## Public fields

- `id`:

  String. Unique identifier for the node.

- `label`:

  String. Human-readable name/label.

- `last_result`:

  List. Results from most recent execution.

- `params`:

  List. Arbitrary metadata/config parameters.

## Methods

### Public methods

- [`AgentNode$new()`](#method-AgentNode-new)

- [`AgentNode$run()`](#method-AgentNode-run)

- [`AgentNode$clone()`](#method-AgentNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentNode

#### Usage

    AgentNode$new(id, label = NULL, params = list())

#### Arguments

- `id`:

  String. A unique identifier for the node. Must be unique within a
  single DAG.

- `label`:

  String. An optional human-readable name for the node. Defaults to the
  `id` if not provided. This label is used in Mermaid visualizations.

- `params`:

  List. An optional named list of arbitrary metadata or configuration
  parameters that are stored on the node and can be accessed during
  execution. Useful for passing static configuration to nodes created
  via factories. Run the Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentNode$run(state, ...)

#### Arguments

- `state`:

  AgentState. An `AgentState` object (typically a `RestrictedState`)
  providing scoped access to the centralized workflow memory.

- `...`:

  Additional arguments. Arbitrary parameters passed from
  `AgentDAG$run()`.

#### Returns

A list with at least `status` (String, e.g., "success", "failed",
"pause") and `output` (Any R object to be integrated back into the
state).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Defining a custom subclass of AgentNode
CustomNode <- R6::R6Class("CustomNode",
  inherit = AgentNode,
  public = list(
    run = function(state, ...) {
      message("Executing custom node: ", self$id)
      list(status = "success", output = "Custom output")
    }
  )
)

node <- CustomNode$new("node_1", label = "My First Node")
```

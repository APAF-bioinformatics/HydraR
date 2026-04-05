# Agent Node Base Class

The base R6 class for all nodes in an AgentDAG.

## Value

An \`AgentNode\` object.

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

  Unique identifier.

- `label`:

  Optional human-readable name.

- `params`:

  Optional named list of parameters. Run the Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentNode$run(state, ...)

#### Arguments

- `state`:

  AgentState object.

- `...`:

  Additional arguments.

#### Returns

List with status, output, and metadata.

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
node <- AgentNode$new("my_node", label = "Custom Node")
```

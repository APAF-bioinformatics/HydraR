# Agent Logic Node R6 Class

A node that executes a synchronous R function.

## Value

An \`AgentLogicNode\` object.

## Super class

[`HydraR::AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
-\> `AgentLogicNode`

## Public fields

- `logic_fn`:

  Function(state) -\> List(status, output).

## Methods

### Public methods

- [`AgentLogicNode$new()`](#method-AgentLogicNode-new)

- [`AgentLogicNode$run()`](#method-AgentLogicNode-run)

- [`AgentLogicNode$clone()`](#method-AgentLogicNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentLogicNode

#### Usage

    AgentLogicNode$new(id, logic_fn, label = NULL, params = list())

#### Arguments

- `id`:

  Unique identifier.

- `logic_fn`:

  Function that takes an AgentState object and returns a list.

- `label`:

  Optional human-readable name.

- `params`:

  Optional list of parameters. Run the Logic Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentLogicNode$run(state, ...)

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

    AgentLogicNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
node <- AgentLogicNode$new("start", function(state) list(status = "success"))
```

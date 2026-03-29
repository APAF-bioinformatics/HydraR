# Agent Node R6 Class

Represents a single execution unit within an orchestration DAG. This is
an abstract base class.

## Public fields

- `id`:

  String. Unique identifier for the node.

- `label`:

  String. Human-readable name/label.

- `last_result`:

  List. Results from most recent execution.

- `params`:

  List. Arbitrary metadata/config parameters. Initialize AgentNode

## Methods

### Public methods

- [`AgentNode$new()`](#method-AgentNode-new)

- [`AgentNode$run()`](#method-AgentNode-run)

- [`AgentNode$clone()`](#method-AgentNode-clone)

------------------------------------------------------------------------

### Method `new()`

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

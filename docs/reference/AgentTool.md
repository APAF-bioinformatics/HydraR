# Agent Tool R6 Class

Defines a tool or action that an agent can perform. Used for
prompt-based tool discovery.

## Public fields

- `name`:

  String. The unique name of the tool.

- `description`:

  String. A clear description of what the tool does.

- `parameters`:

  List. A description of the expected parameters.

- `example`:

  String. An example of how to use the tool.

## Methods

### Public methods

- [`AgentTool$new()`](#method-AgentTool-new)

- [`AgentTool$format()`](#method-AgentTool-format)

- [`AgentTool$clone()`](#method-AgentTool-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentTool

#### Usage

    AgentTool$new(name, description, parameters = list(), example = "")

#### Arguments

- `name`:

  String.

- `description`:

  String.

- `parameters`:

  List or String.

- `example`:

  String. Format for Prompt

------------------------------------------------------------------------

### Method [`format()`](https://rdrr.io/r/base/format.html)

#### Usage

    AgentTool$format()

#### Returns

A formatted string describing the tool.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentTool$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

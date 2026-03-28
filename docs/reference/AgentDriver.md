# Agent Driver R6 Class

Abstract base class for CLI-based LLM drivers.

## Public fields

- `id`:

  String. Unique identifier for the driver. Initialize AgentDriver

## Methods

### Public methods

- [`AgentDriver$new()`](#method-AgentDriver-new)

- [`AgentDriver$call()`](#method-AgentDriver-call)

- [`AgentDriver$clone()`](#method-AgentDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentDriver$new(id)

#### Arguments

- `id`:

  Unique identifier. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AgentDriver$call(prompt, model = NULL, ...)

#### Arguments

- `prompt`:

  String. The prompt to send.

- `model`:

  String. Optional model override.

- `...`:

  Additional arguments.

#### Returns

String. Cleaned response from the LLM.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

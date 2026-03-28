# Copilot CLI Driver R6 Class

Driver for the 'gh copilot' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `CopilotCLIDriver`

## Public fields

- `type`:

  String. Use 'shell' or 'git'. Initialize CopilotCLIDriver

## Methods

### Public methods

- [`CopilotCLIDriver$new()`](#method-CopilotCLIDriver-new)

- [`CopilotCLIDriver$call()`](#method-CopilotCLIDriver-call)

- [`CopilotCLIDriver$clone()`](#method-CopilotCLIDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    CopilotCLIDriver$new(id = "copilot_cli", type = "shell")

#### Arguments

- `id`:

  Unique identifier.

- `type`:

  String. Default type ('shell'). Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    CopilotCLIDriver$call(prompt, type = NULL, ...)

#### Arguments

- `prompt`:

  String.

- `type`:

  String override.

- `...`:

  Additional arguments.

#### Returns

String. Cleaned result.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CopilotCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

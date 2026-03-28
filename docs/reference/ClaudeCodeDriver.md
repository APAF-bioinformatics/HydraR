# Claude CLI Driver R6 Class

Driver for the 'claude' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `ClaudeCodeDriver`

## Public fields

- `model`:

  String. Default model. Initialize ClaudeCodeDriver

## Methods

### Public methods

- [`ClaudeCodeDriver$new()`](#method-ClaudeCodeDriver-new)

- [`ClaudeCodeDriver$call()`](#method-ClaudeCodeDriver-call)

- [`ClaudeCodeDriver$clone()`](#method-ClaudeCodeDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    ClaudeCodeDriver$new(id = "claude_cli", model = "claude-3-5-sonnet-latest")

#### Arguments

- `id`:

  Unique identifier.

- `model`:

  String. Default model. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    ClaudeCodeDriver$call(prompt, model = NULL, ...)

#### Arguments

- `prompt`:

  String.

- `model`:

  String override.

- `...`:

  Additional arguments.

#### Returns

String. Cleaned result.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ClaudeCodeDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

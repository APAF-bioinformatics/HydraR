# Claude CLI Driver R6 Class

Driver for the 'claude' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
-\> `ClaudeCodeDriver`

## Public fields

- `model`:

  String. Default model. Initialize ClaudeCodeDriver

## Methods

### Public methods

- [`ClaudeCodeDriver$new()`](#method-ClaudeCodeDriver-new)

- [`ClaudeCodeDriver$call()`](#method-ClaudeCodeDriver-call)

- [`ClaudeCodeDriver$clone()`](#method-ClaudeCodeDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    ClaudeCodeDriver$new(
      id = "claude_cli",
      model = "claude-3-5-sonnet-latest",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `model`:

  String. Default model.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to isolated Git worktree. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    ClaudeCodeDriver$call(prompt, model = NULL, cli_opts = list(), ...)

#### Arguments

- `prompt`:

  String.

- `model`:

  String override.

- `cli_opts`:

  List.

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

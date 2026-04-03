# Claude CLI Driver R6 Class

Driver for the 'claude' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `AnthropicCLIDriver`

## Public fields

- `model`:

  String. Default model. Initialize AnthropicCLIDriver

## Methods

### Public methods

- [`AnthropicCLIDriver$new()`](#method-AnthropicCLIDriver-new)

- [`AnthropicCLIDriver$call()`](#method-AnthropicCLIDriver-call)

- [`AnthropicCLIDriver$clone()`](#method-AnthropicCLIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AnthropicCLIDriver$new(
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

    AnthropicCLIDriver$call(prompt, model = NULL, cli_opts = list(), ...)

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

    AnthropicCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

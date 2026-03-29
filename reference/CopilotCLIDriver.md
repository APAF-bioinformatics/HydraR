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

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    CopilotCLIDriver$new(
      id = "copilot_cli",
      type = "shell",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `type`:

  String. Default type ('shell').

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to isolated Git worktree. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    CopilotCLIDriver$call(prompt, type = NULL, cli_opts = list(), ...)

#### Arguments

- `prompt`:

  String.

- `type`:

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

    CopilotCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

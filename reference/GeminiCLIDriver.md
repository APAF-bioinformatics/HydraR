# Gemini CLI Driver R6 Class

Driver for the 'gemini' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `GeminiCLIDriver`

## Public fields

- `model`:

  String. Default model. Omit to use CLI default.

## Methods

### Public methods

- [`GeminiCLIDriver$new()`](#method-GeminiCLIDriver-new)

- [`GeminiCLIDriver$call()`](#method-GeminiCLIDriver-call)

- [`GeminiCLIDriver$clone()`](#method-GeminiCLIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize GeminiCLIDriver

#### Usage

    GeminiCLIDriver$new(
      id = "gemini_cli",
      model = "gemini-2.5-flash",
      validation_mode = "warning",
      working_dir = NULL,
      repo_root = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `model`:

  String. Optional model.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to isolated Git worktree.

- `repo_root`:

  String. Path to the main repository root. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    GeminiCLIDriver$call(
      prompt,
      model = NULL,
      system_prompt = NULL,
      cli_opts = list(),
      ...
    )

#### Arguments

- `prompt`:

  String.

- `model`:

  String override.

- `system_prompt`:

  String. Optional system prompt.

- `cli_opts`:

  List. Named list of CLI options.

- `...`:

  Additional arguments.

#### Returns

String. Cleaned result.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    GeminiCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

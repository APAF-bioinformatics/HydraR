# OpenAI Codex CLI Driver R6 Class

A specialized `AgentDriver` for the official `codex` CLI tool (v0.118+).
This model is legacy but still supported for specific code-generation
tasks.

## Value

An `OpenAICodexCLIDriver` object.

## Super class

[`HydraR::AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
-\> `OpenAICodexCLIDriver`

## Methods

### Public methods

- [`OpenAICodexCLIDriver$new()`](#method-OpenAICodexCLIDriver-new)

- [`OpenAICodexCLIDriver$call()`](#method-OpenAICodexCLIDriver-call)

- [`OpenAICodexCLIDriver$clone()`](#method-OpenAICodexCLIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize OpenAICodexCLIDriver

#### Usage

    OpenAICodexCLIDriver$new(
      id = "codex_cli",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  String. Unique identifier.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to isolated Git worktree. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Sends a execution request to the Codex CLI.

#### Usage

    OpenAICodexCLIDriver$call(prompt, system_prompt = NULL, cli_opts = list(), ...)

#### Arguments

- `prompt`:

  String.

- `system_prompt`:

  String. Optional system prompt.

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

    OpenAICodexCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Legacy Codex CLI support
driver <- OpenAICodexCLIDriver$new()

# 2. Isolated execution with skip-checks for specific environments
response <- driver$call(
  prompt = "Create a data.frame with 5 rows and 2 columns.",
  cli_opts = list(
    sandbox = TRUE,
    skip_git_repo_check = TRUE
  )
)
} # }
```

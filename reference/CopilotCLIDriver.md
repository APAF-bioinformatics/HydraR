# Copilot CLI Driver R6 Class

A specialized `AgentDriver` for the GitHub `gh copilot` CLI extension.

## Value

A `CopilotCLIDriver` object.

## Details

**Setup**: Requires the GitHub CLI (`gh`) and the `copilot` extension
(`gh extension install github/gh-copilot`). Must be authenticated via
`gh auth login`.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `CopilotCLIDriver`

## Methods

### Public methods

- [`CopilotCLIDriver$new()`](#method-CopilotCLIDriver-new)

- [`CopilotCLIDriver$call()`](#method-CopilotCLIDriver-call)

- [`CopilotCLIDriver$clone()`](#method-CopilotCLIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize CopilotCLIDriver

#### Usage

    CopilotCLIDriver$new(
      id = "copilot_cli",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to isolated Git worktree. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    CopilotCLIDriver$call(prompt, system_prompt = NULL, cli_opts = list(), ...)

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

    CopilotCLIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Use GitHub Copilot CLI extension
driver <- CopilotCLIDriver$new()

# 2. Request a terminal command with tool permissions
response <- driver$call(
  prompt = "Find all CSV files larger than 1MB and move them to 'data/'",
  cli_opts = list(
    allow_all_tools = TRUE,
    no_custom_instructions = FALSE
  )
)
} # }
```

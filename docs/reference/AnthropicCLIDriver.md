# Anthropic CLI Driver

A specialized `AgentDriver` for the Anthropic `claude` (Claude Code)
CLI. Optimized for terminal-based engineering tasks.

## Value

An `AnthropicCLIDriver` object.

## Details

**Setup**: Requires `claude` (Anthropic CLI) to be installed and
authenticated. Configure the path via
`options(HydraR.claude_path = "...")` or in your `.Renviron`.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `AnthropicCLIDriver`

## Public fields

- `model`:

  String. Default model.

## Methods

### Public methods

- [`AnthropicCLIDriver$new()`](#method-AnthropicCLIDriver-new)

- [`AnthropicCLIDriver$call()`](#method-AnthropicCLIDriver-call)

- [`AnthropicCLIDriver$clone()`](#method-AnthropicCLIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize AnthropicCLIDriver

#### Usage

    AnthropicCLIDriver$new(
      id = "claude_cli",
      model = "sonnet",
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

  String. Optional. Path to isolated Git worktree.

#### Returns

A new \`AnthropicCLIDriver\` object. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AnthropicCLIDriver$call(
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

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Initialize the Claude Code CLI driver
driver <- AnthropicCLIDriver$new(model = "sonnet")

# 2. Execute a complex engineering task with budget constraints
# and permission skipping for non-interactive automation.
response <- driver$call(
  prompt = "Refactor R/dag.R to use R6 private methods.",
  cli_opts = list(
    dangerously_skip_permissions = TRUE,
    max_budget_usd = 5.0,
    verbose = TRUE
  )
)
} # }
```

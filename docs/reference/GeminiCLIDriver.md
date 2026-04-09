# Gemini CLI Driver R6 Class

A specialized `AgentDriver` that invokes the Google `gemini` CLI tool.
This is the preferred driver for workflows requiring local tool use and
filesystem interaction via the Google-native MCP bridge.

## Value

A `GeminiCLIDriver` object.

## Details

**Setup**: Requires the `gemini` CLI to be installed and in your PATH.
You can override the binary path using:
`options(HydraR.gemini_path = "/path/to/gemini")` or by setting the
`HYDRAR_GEMINI_PATH` environment variable in your `.Renviron`.

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

### Method [`new()`](https://rdrr.io/r/methods/new.html)

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

  String. Unique identifier for this driver.

- `model`:

  String. The Gemini model ID (e.g., `"gemini-1.5-flash"`).

- `validation_mode`:

  String. Either `"warning"` or `"strict"`.

- `working_dir`:

  String. Optional. Path to an isolated git worktree where the CLI will
  execute.

- `repo_root`:

  String. Optional. Path to the main repository to enable cross-worktree
  context. Call the LLM

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

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Standard CLI-based agent with model selection
driver <- GeminiCLIDriver$new(model = "gemini-1.5-pro")

# 2. Advanced call with MCP tool discovery and 'YOLO' mode enabled
# This allows the agent to execute tools without interactive confirmation.
response <- driver$call(
  prompt = "Analyze the R scripts in this directory and suggest performance fixes.",
  cli_opts = list(
    allowed_tools = "ls,grep,read_file",
    allowed_mcp_server_names = "filesystem,github",
    yolo = TRUE,
    include_directories = c("R", "tests")
  )
)
} # }
```

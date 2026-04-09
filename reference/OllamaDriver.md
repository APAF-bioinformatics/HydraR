# Ollama Driver R6 Class

A specialized `AgentDriver` for local execution of Open source models
via the `ollama` CLI. Ideal for air-gapped or privacy-sensitive
workflows.

## Value

An `OllamaDriver` object.

## Details

**Setup**: Ensure the `ollama` server is running locally. You can
specify the binary path via `options(HydraR.ollama_path = "...")`.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `OllamaDriver`

## Public fields

- `model`:

  String. Default model.

## Methods

### Public methods

- [`OllamaDriver$new()`](#method-OllamaDriver-new)

- [`OllamaDriver$format_cli_opts()`](#method-OllamaDriver-format_cli_opts)

- [`OllamaDriver$call()`](#method-OllamaDriver-call)

- [`OllamaDriver$clone()`](#method-OllamaDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-get_capabilities)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize OllamaDriver

#### Usage

    OllamaDriver$new(
      id = "ollama",
      model = "llama3.2",
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

  String. Optional. Path to isolated Git worktree. Format CLI Options
  for Ollama

------------------------------------------------------------------------

### Method `format_cli_opts()`

#### Usage

    OllamaDriver$format_cli_opts(cli_opts = list())

#### Arguments

- `cli_opts`:

  List.

#### Returns

Character vector. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    OllamaDriver$call(
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

    OllamaDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Use llama3 locally via Ollama
driver <- OllamaDriver$new(model = "llama3")

# Call with context size adjustments
response <- driver$call(
  prompt = "Summarize the R documentation for 'lapply'.",
  cli_opts = list(num_ctx = 8192)
)
} # }
```

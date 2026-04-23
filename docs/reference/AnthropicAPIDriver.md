# Anthropic API Driver

A specialized `AgentDriver` for the Anthropic Messages API, providing
access to the Claude family of models.

## Value

An `AnthropicAPIDriver` object.

## Details

**Setup**: To use this driver, you must set the `ANTHROPIC_API_KEY`
environment variable. It is recommended to add this to your `.Renviron`
file: `ANTHROPIC_API_KEY="sk-ant-..."`

## Super class

[`HydraR::AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
-\> `AnthropicAPIDriver`

## Public fields

- `api_url`:

  String. Base URL.

## Methods

### Public methods

- [`AnthropicAPIDriver$new()`](#method-AnthropicAPIDriver-new)

- [`AnthropicAPIDriver$get_capabilities()`](#method-AnthropicAPIDriver-get_capabilities)

- [`AnthropicAPIDriver$call()`](#method-AnthropicAPIDriver-call)

- [`AnthropicAPIDriver$clone()`](#method-AnthropicAPIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize AnthropicAPIDriver

#### Usage

    AnthropicAPIDriver$new(
      id = "anthropic_api",
      model = "claude-sonnet-4-6",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  String. Unique identifier for this driver instance.

- `model`:

  String. The Anthropic model ID (e.g., `"claude-3-sonnet"`).

- `validation_mode`:

  String. Driver validation strictness level.

- `working_dir`:

  String. Optional. Base directory for file-system operations.

#### Returns

A new `AnthropicAPIDriver` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    AnthropicAPIDriver$get_capabilities()

#### Returns

A list of capabilities. Call Anthropic API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AnthropicAPIDriver$call(
      prompt,
      model = NULL,
      system_prompt = NULL,
      cli_opts = list(),
      ...
    )

#### Arguments

- `prompt`:

  String. The prompt text.

- `model`:

  String. Optional model override.

- `system_prompt`:

  String. Optional system prompt.

- `cli_opts`:

  List. Additional API options.

- `...`:

  Additional arguments.

#### Returns

String. LLM response.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AnthropicAPIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Initialize the Claude Messages API driver
driver <- AnthropicAPIDriver$new(model = "claude-3-opus-20240229")

# 2. Perform a research task with reasoning constraints
response <- driver$call(
  prompt = "Summarize the differences between S3 and R6 classes in R.",
  system_prompt = "You are a technical documentarian. Use markdown tables.",
  cli_opts = list(
    temperature = 0.2,
    max_tokens = 1024,
    stop_sequences = list("### Conclusion")
  )
)
message(response)
} # }
```

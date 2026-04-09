# OpenAI API Driver

A specialized `AgentDriver` that interacts with the OpenAI Chat
Completions API. Requires an active OpenAI account and API key.

## Value

An `OpenAIAPIDriver` object.

## Details

**Setup**: To use this driver, you must set the `OPENAI_API_KEY`
environment variable. It is recommended to add this to your `.Renviron`
file: `OPENAI_API_KEY="sk-..."`

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `OpenAIAPIDriver`

## Public fields

- `api_url`:

  String. Base URL.

## Methods

### Public methods

- [`OpenAIAPIDriver$new()`](#method-OpenAIAPIDriver-new)

- [`OpenAIAPIDriver$get_capabilities()`](#method-OpenAIAPIDriver-get_capabilities)

- [`OpenAIAPIDriver$call()`](#method-OpenAIAPIDriver-call)

- [`OpenAIAPIDriver$clone()`](#method-OpenAIAPIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)

------------------------------------------------------------------------

### Method `new()`

Initialize OpenAIAPIDriver

#### Usage

    OpenAIAPIDriver$new(
      id = "openai_api",
      model = "gpt-5.4-mini",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  String. Unique identifier for this driver instance.

- `model`:

  String. The OpenAI model ID (e.g., `"gpt-4"`, `"gpt-3.5-turbo"`).

- `validation_mode`:

  String. Either `"warning"` or `"strict"`. Controls how schema
  mismatches are handled.

- `working_dir`:

  String. Optional. The directory where output files should be
  generated.

#### Returns

A new `OpenAIAPIDriver` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    OpenAIAPIDriver$get_capabilities()

#### Returns

A list of capabilities. Call OpenAI API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    OpenAIAPIDriver$call(
      prompt,
      model = NULL,
      system_prompt = NULL,
      cli_opts = list(),
      ...
    )

#### Arguments

- `prompt`:

  String. The primary user message or instruction sent to the LLM.

- `model`:

  String. Optional model override for this specific call.

- `system_prompt`:

  String. Optional system-level instruction (role-playing or
  constraint).

- `cli_opts`:

  List. Additional parameters passed to the JSON body (e.g.,
  `temperature = 0.7`).

- `...`:

  Additional arguments. Passed through to the internal request handler.

#### Returns

String. The text content of the LLM's response.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    OpenAIAPIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Ensure OPENAI_API_KEY is set in .Renviron
driver <- OpenAIAPIDriver$new(model = "gpt-4-turbo")

# Perform a basic call
response <- driver$call("What is the capital of France?")
message(response)
} # }
```

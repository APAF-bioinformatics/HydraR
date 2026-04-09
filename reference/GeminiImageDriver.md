# Gemini Image API Driver R6 Class

Driver for Google Gemini's multimodal image generation (2026 models).

## Value

A \`GeminiImageDriver\` R6 object.

## Super classes

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\>
[`HydraR::GeminiAPIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiAPIDriver.md)
-\> `GeminiImageDriver`

## Public fields

- `output_dir`:

  String. Directory to save generated images.

- `aspect_ratio`:

  String. Default "16:9".

## Methods

### Public methods

- [`GeminiImageDriver$new()`](#method-GeminiImageDriver-new)

- [`GeminiImageDriver$call()`](#method-GeminiImageDriver-call)

- [`GeminiImageDriver$clone()`](#method-GeminiImageDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_no_injection)
- [`HydraR::GeminiAPIDriver$get_capabilities()`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiAPIDriver.html#method-get_capabilities)

------------------------------------------------------------------------

### Method `new()`

Initialize GeminiImageDriver

#### Usage

    GeminiImageDriver$new(
      id = "gemini_image",
      model = "gemini-3.1-flash-image-preview",
      output_dir = "images",
      aspect_ratio = "1:1",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  String.

- `model`:

  String. Default "imagen-3.0-generate-001".

- `output_dir`:

  String.

- `aspect_ratio`:

  String.

- `validation_mode`:

  String.

- `working_dir`:

  String. Call Gemini Image API (Multimodal Unified)

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

Sends a prompt to Gemini for image generation.

#### Usage

    GeminiImageDriver$call(
      prompt,
      model = NULL,
      system_prompt = NULL,
      cli_opts = list(),
      ...
    )

#### Arguments

- `prompt`:

  String. Image prompt.

- `model`:

  String. Optional override.

- `system_prompt`:

  String. Optional system prompt.

- `cli_opts`:

  List. Parameters (aspectRatio, etc).

- `...`:

  Additional arguments.

#### Returns

String. Local path to the generated image.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    GeminiImageDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
driver <- GeminiImageDriver$new()
} # }
```

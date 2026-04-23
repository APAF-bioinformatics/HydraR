# Gemini Image API Driver R6 Class

A specialized driver for Gemini's multimodal and image generation
capabilities (supporting Imagen and native Gemini 3.x modalities).

## Value

A `GeminiImageDriver` R6 object.

## Details

**Setup**: Requires `GOOGLE_API_KEY` in your `.Renviron`.

## Super classes

[`HydraR::AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
-\>
[`HydraR::GeminiAPIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/GeminiAPIDriver.md)
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

- [`HydraR::AgentDriver$exec_in_dir()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$filter_llm_noise()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-filter_llm_noise)
- [`HydraR::AgentDriver$format_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_cli_opts)
- [`HydraR::AgentDriver$validate_no_injection()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_no_injection)
- [`HydraR::GeminiAPIDriver$get_capabilities()`](https://APAF-bioinformatics.github.io/HydraR/reference/GeminiAPIDriver.html#method-get_capabilities)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

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

  String. Unique identifier for the image driver.

- `model`:

  String. Google model ID (defaults to multimodal flash).

- `output_dir`:

  String. The directory where generated images will be saved.

- `aspect_ratio`:

  String. The default aspect ratio for generated images (e.g., `"16:9"`,
  `"1:1"`).

- `validation_mode`:

  String. Controls schema enforcement.

- `working_dir`:

  String. Optional path for isolated execution.

#### Returns

A new `GeminiImageDriver` instance. Call Gemini Image API (Multimodal
Unified)

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
# 1. Generate a high-resolution laboratory illustration
# Multimodal Gemini 3.1 models infer dimensions from prompt + config
driver <- GeminiImageDriver$new(output_dir = "assets/media")

# 2. Request a specific aspect ratio and filename
img_path <- driver$call(
  prompt = "A futuristic bioinformatics lab with DNA holograms, hyper-realistic, 8k",
  cli_opts = list(
    aspectRatio = "16:9",
    sampleCount = 1,
    filename = "hero_dna_lab.png"
  )
)
message("Hero image saved to: ", img_path)
} # }
```

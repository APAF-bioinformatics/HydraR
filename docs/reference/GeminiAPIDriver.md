# Gemini API Driver R6 Class

Driver for Google Gemini (AI Studio) API.

## Value

A \`GeminiAPIDriver\` R6 object.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `GeminiAPIDriver`

## Public fields

- `api_base`:

  String. Base URL. Initialize GeminiAPIDriver

## Methods

### Public methods

- [`GeminiAPIDriver$new()`](#method-GeminiAPIDriver-new)

- [`GeminiAPIDriver$get_capabilities()`](#method-GeminiAPIDriver-get_capabilities)

- [`GeminiAPIDriver$call()`](#method-GeminiAPIDriver-call)

- [`GeminiAPIDriver$clone()`](#method-GeminiAPIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    GeminiAPIDriver$new(
      id = "gemini_api",
      model = "gemini-1.5-pro",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  String. Unique identifier.

- `model`:

  String. Model name.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional. Path to worktree.

#### Returns

A new \`GeminiAPIDriver\` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    GeminiAPIDriver$get_capabilities()

#### Returns

A list of capabilities. Call Gemini API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    GeminiAPIDriver$call(prompt, model = NULL, cli_opts = list(), ...)

#### Arguments

- `prompt`:

  String. The prompt text.

- `model`:

  String. Optional model override.

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

    GeminiAPIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

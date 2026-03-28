# Gemini CLI Driver R6 Class

Driver for the 'gemini' CLI tool.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `GeminiCLIDriver`

## Public fields

- `model`:

  String. Default model. Omit to use CLI default. Initialize
  GeminiCLIDriver

## Methods

### Public methods

- [`GeminiCLIDriver$new()`](#method-GeminiCLIDriver-new)

- [`GeminiCLIDriver$call()`](#method-GeminiCLIDriver-call)

- [`GeminiCLIDriver$clone()`](#method-GeminiCLIDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    GeminiCLIDriver$new(id = "gemini_cli", model = NULL)

#### Arguments

- `id`:

  Unique identifier.

- `model`:

  String. Optional model. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    GeminiCLIDriver$call(prompt, model = NULL, ...)

#### Arguments

- `prompt`:

  String.

- `model`:

  String override.

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

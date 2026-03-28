# Ollama Driver R6 Class

Driver for the 'ollama' CLI tool (local).

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `OllamaDriver`

## Public fields

- `model`:

  String. Default model. Initialize OllamaDriver

## Methods

### Public methods

- [`OllamaDriver$new()`](#method-OllamaDriver-new)

- [`OllamaDriver$call()`](#method-OllamaDriver-call)

- [`OllamaDriver$clone()`](#method-OllamaDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    OllamaDriver$new(id = "ollama", model = "llama3.2")

#### Arguments

- `id`:

  Unique identifier.

- `model`:

  String. Default model. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    OllamaDriver$call(prompt, model = NULL, ...)

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

    OllamaDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

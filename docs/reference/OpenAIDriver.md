# OpenAI API Driver R6 Class

Driver for OpenAI Chat Completions API.

## Value

An \`OpenAIAPIDriver\` R6 object.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `OpenAIAPIDriver`

## Public fields

- `api_url`:

  String. Base URL. Initialize OpenAIAPIDriver

## Methods

### Public methods

- [`OpenAIAPIDriver$new()`](#method-OpenAIAPIDriver-new)

- [`OpenAIAPIDriver$get_capabilities()`](#method-OpenAIAPIDriver-get_capabilities)

- [`OpenAIAPIDriver$call()`](#method-OpenAIAPIDriver-call)

- [`OpenAIAPIDriver$clone()`](#method-OpenAIAPIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    OpenAIAPIDriver$new(
      id = "openai_api",
      model = "gpt-4o",
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

A new \`OpenAIAPIDriver\` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    OpenAIAPIDriver$get_capabilities()

#### Returns

A list of capabilities. Call OpenAI API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    OpenAIAPIDriver$call(prompt, model = NULL, cli_opts = list(), ...)

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

    OpenAIAPIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

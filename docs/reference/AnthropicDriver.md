# Anthropic API Driver R6 Class

Driver for Anthropic Messages API.

## Value

An \`AnthropicDriver\` R6 object.

## Super class

[`HydraR::AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
-\> `AnthropicDriver`

## Public fields

- `api_url`:

  String. Base URL. Initialize AnthropicDriver

## Methods

### Public methods

- [`AnthropicDriver$new()`](#method-AnthropicDriver-new)

- [`AnthropicDriver$get_capabilities()`](#method-AnthropicDriver-get_capabilities)

- [`AnthropicDriver$call()`](#method-AnthropicDriver-call)

- [`AnthropicDriver$clone()`](#method-AnthropicDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AnthropicDriver$new(
      id = "anthropic_api",
      model = "claude-3-5-sonnet-20241022",
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

A new \`AnthropicDriver\` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    AnthropicDriver$get_capabilities()

#### Returns

A list of capabilities. Call Anthropic API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AnthropicDriver$call(prompt, model = NULL, cli_opts = list(), ...)

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

    AnthropicDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

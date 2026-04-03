# Anthropic API Driver R6 Class

Driver for Anthropic Messages API.

## Value

An \`AnthropicAPIDriver\` R6 object.

## Super class

[`HydraR::AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
-\> `AnthropicAPIDriver`

## Public fields

- `api_url`:

  String. Base URL. Initialize AnthropicAPIDriver

## Methods

### Public methods

- [`AnthropicAPIDriver$new()`](#method-AnthropicAPIDriver-new)

- [`AnthropicAPIDriver$get_capabilities()`](#method-AnthropicAPIDriver-get_capabilities)

- [`AnthropicAPIDriver$call()`](#method-AnthropicAPIDriver-call)

- [`AnthropicAPIDriver$clone()`](#method-AnthropicAPIDriver-clone)

Inherited methods

- [`HydraR::AgentDriver$exec_in_dir()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-exec_in_dir)
- [`HydraR::AgentDriver$format_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-format_cli_opts)
- [`HydraR::AgentDriver$validate_cli_opts()`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.html#method-validate_cli_opts)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AnthropicAPIDriver$new(
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

A new \`AnthropicAPIDriver\` object. Get Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    AnthropicAPIDriver$get_capabilities()

#### Returns

A list of capabilities. Call Anthropic API

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AnthropicAPIDriver$call(prompt, model = NULL, cli_opts = list(), ...)

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

    AnthropicAPIDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

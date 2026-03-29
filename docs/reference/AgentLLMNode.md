# Agent LLM Node R6 Class

A specialized AgentNode that executes LLM calls via a Driver.

## Value

An \`AgentLLMNode\` R6 object.

## Super class

[`HydraR::AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
-\> `AgentLLMNode`

## Public fields

- `role`:

  String. System prompt/role for the agent.

- `model`:

  String. Default model.

- `driver`:

  AgentDriver object.

- `output_format`:

  String. Output expectation.

- `cli_opts`:

  List. Default CLI options for the driver.

- `prompt_builder`:

  Function(state) -\> String.

- `tools`:

  List of AgentTool objects. Initialize AgentLLMNode

## Methods

### Public methods

- [`AgentLLMNode$new()`](#method-AgentLLMNode-new)

- [`AgentLLMNode$run()`](#method-AgentLLMNode-run)

- [`AgentLLMNode$swap_driver()`](#method-AgentLLMNode-swap_driver)

- [`AgentLLMNode$clone()`](#method-AgentLLMNode-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentLLMNode$new(
      id,
      role,
      driver,
      model = NULL,
      cli_opts = list(),
      prompt_builder = NULL,
      tools = list(),
      label = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `role`:

  System prompt.

- `driver`:

  AgentDriver object.

- `model`:

  String. Optional model override.

- `cli_opts`:

  List. Optional default CLI options.

- `prompt_builder`:

  Function(state) -\> String.

- `tools`:

  List of AgentTool objects.

- `label`:

  Optional human-readable name. Run the LLM Node

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentLLMNode$run(state, ...)

#### Arguments

- `state`:

  AgentState object.

- `...`:

  Additional arguments.

#### Returns

List with status, output, and metadata. Swap Driver at Runtime

------------------------------------------------------------------------

### Method `swap_driver()`

#### Usage

    AgentLLMNode$swap_driver(driver)

#### Arguments

- `driver`:

  AgentDriver object or String ID.

#### Returns

The Node (invisibly).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentLLMNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
driver <- GeminiCLIDriver$new()
node <- AgentLLMNode$new("research", role = "Researcher", driver = driver)
} # }
```

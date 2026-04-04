# Agent LLM Node R6 Class

A node that uses an LLM driver for execution.

## Value

An \`AgentLLMNode\` object.

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

  List of AgentTool objects.

- `agents_files`:

  Character vector. Paths to agents context files.

- `skills_files`:

  Character vector. Paths to skills context files.

## Methods

### Public methods

- [`AgentLLMNode$new()`](#method-AgentLLMNode-new)

- [`AgentLLMNode$run()`](#method-AgentLLMNode-run)

- [`AgentLLMNode$swap_driver()`](#method-AgentLLMNode-swap_driver)

- [`AgentLLMNode$clone()`](#method-AgentLLMNode-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentLLMNode

#### Usage

    AgentLLMNode$new(
      id,
      role,
      driver,
      model = NULL,
      cli_opts = list(),
      prompt_builder = NULL,
      tools = list(),
      label = NULL,
      params = list(),
      agents_files = NULL,
      skills_files = NULL
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

  Optional human-readable name.

- `params`:

  Optional list of parameters.

- `agents_files`:

  Optional character vector of paths to agents.md files.

- `skills_files`:

  Optional character vector of paths to skills.md files. Run the LLM
  Node

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
node <- AgentLLMNode$new("chat", role = "helpful assistant")
} # }
```

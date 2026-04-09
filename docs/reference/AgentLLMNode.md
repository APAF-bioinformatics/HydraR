# Agent LLM Node R6 Class

A specialized `AgentNode` that leverages a Large Language Model (LLM) to
generate outputs from prompts. It manages prompt construction by
combining a persistent `role` (system prompt) with dynamic context from
the `AgentState`. It also handles tool injection and automatic context
discovery from local files (e.g., `agents.md`, `skills.md`).

## Value

An `AgentLLMNode` object.

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

  String. Unique identifier for the node.

- `role`:

  String. The primary system prompt or persona the LLM should assume.

- `driver`:

  AgentDriver. An instance of an `AgentDriver` subclass (CLI or API
  based).

- `model`:

  String. Optional. The specific model to use (overrides driver
  default).

- `cli_opts`:

  List. Optional. Named list of parameters for the LLM call (e.g.,
  temperature).

- `prompt_builder`:

  Function. Optional. A function that takes an `AgentState` and returns
  a string prompt. If omitted, the node serializes the entire state as
  JSON.

- `tools`:

  List. A list of `AgentTool` objects available for the agent to use.

- `label`:

  String. Human-readable name for visualization.

- `params`:

  List. Additional configuration (e.g., `output_format="r"`).

- `agents_files`:

  Character vector. Optional paths to markdown files containing agent
  interaction guidelines.

- `skills_files`:

  Character vector. Optional paths to markdown files containing
  specialized tool instructions. Run the LLM Node

------------------------------------------------------------------------

### Method `run()`

Executes the LLM call. This method handles prompt construction, tool
injection, context file discovery, and driver invocation.

#### Usage

    AgentLLMNode$run(state, ...)

#### Arguments

- `state`:

  AgentState. The centralized state object for the workflow.

- `...`:

  Additional arguments. Passed through to the driver's
  [`call()`](https://rdrr.io/r/base/call.html) method.

#### Returns

A list containing `status`, `output` (the LLM response), `raw` (the full
driver response), and meta-information. Swap Driver at Runtime

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
# NOTE: Set ANTHROPIC_API_KEY in your .Renviron file
driver <- AnthropicAPIDriver$new()

# Create a node with a prompt builder that pulls from state
node <- AgentLLMNode$new(
  id = "summarizer",
  role = "You are a concise summarizer.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Summarise this text: %s", state$get("input_text"))
  }
)
} # }
```

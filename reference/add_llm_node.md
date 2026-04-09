# Create an LLM Agent Node

A convenience wrapper to instantiate an `AgentLLMNode`. Useful for
functional-style DAG construction.

## Usage

``` r
add_llm_node(id, role, driver, model = NULL, cli_opts = list(), ...)
```

## Arguments

- id:

  String. A unique identifier for the node within the DAG.

- role:

  String. The system prompt or identity the LLM should assume (e.g.,
  "Python Developer").

- driver:

  AgentDriver. An R6 driver object (e.g., `GeminiCLIDriver`) that
  handles the LLM API.

- model:

  String. Optional model name override (e.g., "gpt-4"). Defaults to
  driver default.

- cli_opts:

  List. Optional parameters passed to the underlying CLI or API call.

- ...:

  Additional arguments. Passed directly to the `AgentLLMNode$new()`
  constructor. Useful for setting `tools`, `prompt_builder`, or
  `output_path`.

## Value

An `AgentLLMNode` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# NOTE: Ensure ANTHROPIC_API_KEY is set in your .Renviron file for this example.

driver <- AnthropicAPIDriver$new()
node <- add_llm_node(
  id = "coder",
  role = "You are an expert R programmer.",
  driver = driver,
  model = "claude-3-sonnet",
  output_path = "scripts/generated_code.R"
)
} # }
```

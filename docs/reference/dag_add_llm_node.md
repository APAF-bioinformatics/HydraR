# Add an LLM Agent Node directly to a DAG

Instantiates an `AgentLLMNode` and appends it to the provided `AgentDAG`
in one step.

## Usage

``` r
dag_add_llm_node(dag, id, role, driver, model = NULL, cli_opts = list(), ...)
```

## Arguments

- dag:

  AgentDAG. The graph object to which the node will be added.

- id:

  String. Unique identifier for the node.

- role:

  String. System prompt/role for the agent.

- driver:

  AgentDriver. The LLM driver instance.

- model:

  String. Optional model name override.

- cli_opts:

  List. Optional CLI/API parameters.

- ...:

  Additional arguments. Passed to `AgentLLMNode$new()`.

## Value

The modified `AgentDAG` object (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
# Chaining nodes using the functional API
# This pattern is common in complex HydraR orchestration scripts.
dag <- dag_create() |>
  dag_add_llm_node(
    id = "writer",
    role = "Academic technical writer",
    driver = OpenAIAPIDriver$new(api_key = Sys.getenv("OPENAI_API_KEY"), model = "gpt-4-turbo")
  ) |>
  dag_add_llm_node(
    id = "critic",
    role = "Peer reviewer",
    driver = AnthropicAPIDriver$new(api_key = Sys.getenv("ANTHROPIC_API_KEY"), model = "claude-3-sonnet"),
    cli_opts = list(temperature = 0.2)
  )
} # }
```

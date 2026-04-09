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
# NOTE: Set GOOGLE_API_KEY in your .Renviron for Gemini drivers.

dag <- dag_create()
dag_add_llm_node(
  dag,
  id = "summary_node",
  role = "Summarise the following text.",
  driver = GeminiAPIDriver$new()
)
} # }
```

# Add an LLM Agent Node directly to a DAG

Add an LLM Agent Node directly to a DAG

## Usage

``` r
dag_add_llm_node(dag, id, role, driver, model = NULL, cli_opts = list(), ...)
```

## Arguments

- dag:

  AgentDAG object.

- id:

  String. Unique identifier for the node.

- role:

  String. System prompt/role for the agent.

- driver:

  AgentDriver object.

- model:

  String. Optional model override.

- cli_opts:

  List. Optional CLI options.

- ...:

  Additional arguments passed to AgentLLMNode\$new()

## Value

The modified AgentDAG object (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
dag <- dag_create()
dag <- dag_add_llm_node(dag, "node1", "Assistant", AnthropicAPIDriver$new())
} # }
```

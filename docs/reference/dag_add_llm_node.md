# Add an LLM Agent Node directly to a DAG

Add an LLM Agent Node directly to a DAG

## Usage

``` r
dag_add_llm_node(dag, id, role, driver, ...)
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

- ...:

  Additional arguments passed to AgentLLMNode\$new()

## Value

The modified AgentDAG object (invisibly).

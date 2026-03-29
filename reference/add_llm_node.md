# Create an LLM Agent Node easily

Create an LLM Agent Node easily

## Usage

``` r
add_llm_node(id, role, driver, model = NULL, cli_opts = list(), ...)
```

## Arguments

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

AgentLLMNode object.

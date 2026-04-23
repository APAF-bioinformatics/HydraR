# Automatic Node Factory for Mermaid-as-Source

Generates a closure that can resolve Mermaid node labels into fully
instantiated `AgentNode` objects based on inline annotations.

## Usage

``` r
auto_node_factory(driver_registry = NULL)
```

## Arguments

- driver_registry:

  DriverRegistry. An optional registry used to resolve drivers specified
  in Mermaid annotations (e.g., `driver=openai_api`).

## Value

A function that takes `(id, label, params)` and returns an `AgentNode`.

## Details

The factory supports the following `type=` parameters in Mermaid labels:

- `llm`: Creates an `AgentLLMNode`. Requires `role` or `role_id`.

- `logic`: Creates an `AgentLogicNode`. Requires `logic_id`.

- `router`: Creates an `AgentRouterNode`. Requires `logic_id`.

- `map`: Creates an `AgentMapNode`. Requires `logic_id` and `map_key`.

## Examples

``` r
if (FALSE) { # \dontrun{
# 'Low Code' workflow: resolve complex attributes from a Mermaid string
mermaid_src <- '
graph TD
  A["Data Fetcher | type=llm | role=Expert Bioinformatician | model=gpt-4o"]
  B["Quality Gate | type=logic | logic_id=validate_data"]
  C["Reporter | type=llm | role=Technical Writer | driver=claude_cli"]

  A --> B
  B --> C
'

# 1. Register the required logic in the registry
register_logic("validate_data", function(state) {
  raw <- state$get("A")
  if (nchar(raw) > 100) list(status = "success") else list(status = "failed")
})

# 2. Create the DAG using the automatic factory
factory <- auto_node_factory()
dag <- mermaid_to_dag(mermaid_src, node_factory = factory)

# Result: n1 is an AgentLLMNode (OpenAI), n2 is Logic, n3 is AgentLLMNode (Claude)
} # }
```

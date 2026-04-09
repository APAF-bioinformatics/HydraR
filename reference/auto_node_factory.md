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
# Define a workflow entirely in Mermaid syntax
mermaid_src <- '
graph TD
  A["Researcher | type=llm | role=Research Assistant | driver=gemini"]
  B["Validator | type=logic | logic_id=validate_fn"]
  A --> B
'

# Define the logic referenced in Mermaid
register_logic("validate_fn", function(state) {
  list(status = "success", output = list(ok = TRUE))
})

# Spawn the DAG using the automatic factory
dag <- AgentDAG$from_mermaid(
  mermaid_src,
  node_factory = auto_node_factory()
)
} # }
```

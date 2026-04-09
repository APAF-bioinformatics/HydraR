# Automatic Node Factory for Mermaid-as-Source

Returns a node factory closure that resolves \`type=\` annotations
directly from Mermaid node parameters. Eliminates the need for
hand-written factory functions per workflow.

## Usage

``` r
auto_node_factory(driver_registry = NULL)
```

## Arguments

- driver_registry:

  Optional DriverRegistry object. Defaults to global.

## Value

A function(id, label, params) -\> AgentNode.

## Examples

``` r
if (FALSE) { # \dontrun{
mermaid_src <- '
graph TD
  A["Researcher | type=llm | role=Research Assistant | driver=gemini"]
  B["Validator | type=logic | logic_id=validate_fn"]
  A --> B
'
dag <- AgentDAG$from_mermaid(mermaid_src, node_factory = auto_node_factory())
} # }
```

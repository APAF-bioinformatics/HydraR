# Create AgentDAG from Mermaid

Create AgentDAG from Mermaid

## Usage

``` r
mermaid_to_dag(mermaid_str, node_factory = auto_node_factory())
```

## Arguments

- mermaid_str:

  String. Mermaid syntax.

- node_factory:

  Function(id, label) -\> AgentNode. Defaults to
  \`auto_node_factory()\`.

## Value

The AgentDAG object.

## Examples

``` r
if (FALSE) { # \dontrun{
dag <- mermaid_to_dag("graph TD; A-->B;")
} # }
```

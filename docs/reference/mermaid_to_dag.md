# Create AgentDAG from Mermaid

Create AgentDAG from Mermaid

## Usage

``` r
mermaid_to_dag(mermaid_str, node_factory)
```

## Arguments

- mermaid_str:

  String. Mermaid syntax.

- node_factory:

  Function(id, label) -\> AgentNode.

## Value

The AgentDAG object.

# Parse Mermaid Flowchart Syntax

Extracts nodes and edges from 'graph TD' or 'flowchart TD' strings.
Supports basic node labels and directed edges.

## Usage

``` r
parse_mermaid(mermaid_str)
```

## Arguments

- mermaid_str:

  String. Mermaid syntax.

## Value

List with 'nodes' (data.frame) and 'edges' (data.frame).

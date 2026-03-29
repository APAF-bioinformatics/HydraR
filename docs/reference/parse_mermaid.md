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

A list containing \`nodes\` (data.frame) and \`edges\` (data.frame).

## Examples

``` r
mermaid <- "graph TD\n  A --> B"
parse_mermaid(mermaid)
#> $nodes
#>   id label params
#> A  A     A   NULL
#> B  B     B   NULL
#> 
#> $edges
#>   from to label
#> 1    A  B      
#> 
```

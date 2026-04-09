# Add an R Logic Node directly to a DAG

Add an R Logic Node directly to a DAG

## Usage

``` r
dag_add_logic_node(dag, id, logic_fn, ...)
```

## Arguments

- dag:

  AgentDAG object.

- id:

  String. Unique identifier for the node.

- logic_fn:

  Function. Pure R function taking an AgentState object.

- ...:

  Additional arguments passed to AgentLogicNode\$new()

## Value

The modified AgentDAG object (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
dag <- dag_create()
dag <- dag_add_logic_node(dag, "node1", function() print("Hello"))
} # }
```

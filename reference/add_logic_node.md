# Create an R Logic Node easily

Create an R Logic Node easily

## Usage

``` r
add_logic_node(id, logic_fn, ...)
```

## Arguments

- id:

  String. Unique identifier for the node.

- logic_fn:

  Function. Pure R function taking an AgentState object.

- ...:

  Additional arguments passed to AgentLogicNode\$new()

## Value

AgentLogicNode object.

## Examples

``` r
if (FALSE) { # \dontrun{
add_logic_node("logic1", function() print("Logic"))
} # }
```

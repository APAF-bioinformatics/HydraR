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
# Adding logic nodes to a production pipeline
dag <- dag_create() |>
  dag_add_llm_node("planner", "Project Manager", GeminiCLIDriver$new()) |>
  dag_add_logic_node("audit_check", function(state) {
    # Log state for external observability
    message("Auditing current progress...")
    list(status = "success", output = list(timestamp = Sys.time()))
  })
} # }
```

# Advanced Mermaid Parameters

This vignette demonstrates how to use the `HydraR` Mermaid interpreter
to inject parameters directly into nodes using pipe-delimited labels.

## Parameter Syntax

In your Mermaid specification, you can include parameters within a
node’s label:

``` mermaid
graph TD
  A["Initial Research | retries=3 | workdir=./w1"] --> B["Analysis | verbose=true"]
  B --> C["Report | workdir=./output"]
```

## Setup

## Defining the Workflow Components

To keep our architecture clean, we store the logic for our custom nodes
in a central registry.

``` r

param_logic_registry <- list(
  # 1. Custom Node Logic
  logic = list(
    Default = function(state, params = list()) {
      # This function will be called by our CustomNode class
      param_str <- if (length(params) > 0) {
        paste(names(params), params, sep = "=", collapse = ", ")
      } else {
        "none"
      }
      message(sprintf("   [%s] Executing logic... (Params: %s)", state$node_id, param_str))
      list(status = "SUCCESS", output = paste("Result from", state$node_id))
    }
  )
)
```

## The Node Factory

We use a factory function to dynamically resolve nodes and inject
parameters parsed from the Mermaid graph.

``` r

# 1. Define a Specialized Node Factory
param_node_factory <- function(id, label, params = list()) {
  # Create a custom node class for this example
  CustomNode <- R6::R6Class("CustomNode",
    inherit = AgentNode,
    public = list(
      run = function(state) {
        # Delegate to our registry logic
        param_logic_registry$logic$Default(state, self$params)
      }
    )
  )

  CustomNode$new(id, label, params)
}
```

## Instantiating and Running the DAG

``` r

# Define the spec
mermaid_spec <- "
graph TD
  A[\"Initial Research | retries=3 | workdir=./w1\"] --> B[\"Analysis | verbose=true\"]
  B --> C[\"Report | workdir=./output\"]
"

# Create DAG from Mermaid using the standard method
dag <- AgentDAG$from_mermaid(mermaid_spec, node_factory = param_node_factory)

# Verify Parameter Injection
print(dag$nodes$A$params)
#> $retries
#> [1] 3
#> 
#> $workdir
#> [1] "./w1"
print(dag$nodes$B$params)
#> $verbose
#> [1] TRUE

# Run the DAG
dag$run(initial_state = list(input = "test data"))
#> Graph compiled successfully.
#> [Linear] Running Node: A
#>    [A] Executing logic... (Params: retries=3, workdir=./w1)
#> [Linear] Running Node: B
#>    [B] Executing logic... (Params: verbose=TRUE)
#> [Linear] Running Node: C
#>    [C] Executing logic... (Params: workdir=./output)
#> $results
#> $results$A
#> $results$A$status
#> [1] "SUCCESS"
#> 
#> $results$A$output
#> [1] "Result from A"
#> 
#> 
#> $results$B
#> $results$B$status
#> [1] "SUCCESS"
#> 
#> $results$B$output
#> [1] "Result from B"
#> 
#> 
#> $results$C
#> $results$C$status
#> [1] "SUCCESS"
#> 
#> $results$C$output
#> [1] "Result from C"
#> 
#> 
#> 
#> $state
#> <AgentState>
#>   Public:
#>     clone: function (deep = FALSE) 
#>     data: environment
#>     get: function (key, default = NULL) 
#>     get_all: function () 
#>     initialize: function (initial_data = list(), reducers = list(), schema = list()) 
#>     reducers: list
#>     schema: list
#>     set: function (key, value) 
#>     to_list_serializable: function () 
#>     update: function (updates) 
#>     validate: function (key, value) 
#> 
#> $status
#> [1] "completed"
```

## Round-Trip Visualization

You can also use the `plot(details = TRUE)` method to export your DAG
back to Mermaid with the parameters preserved or filtered.

``` r

# Show all parameters
cat(dag$plot(details = TRUE))
```

    #> ```mermaid
    #> graph TD
    #>   A["Initial Research | retries=3 | workdir=./w1"]
    #>   B["Analysis | verbose=TRUE"]
    #>   C["Report | workdir=./output"]
    #>   A --> B
    #>   B --> C
    #> ``` 
    #> ```mermaid
    #> graph TD
    #>   A["Initial Research | retries=3 | workdir=./w1"]
    #>   B["Analysis | verbose=TRUE"]
    #>   C["Report | workdir=./output"]
    #>   A --> B
    #>   B --> C
    #> ```

``` r


# Filter to specific parameters
cat(dag$plot(details = TRUE, include_params = "retries"))
```

    #> ```mermaid
    #> graph TD
    #>   A["Initial Research | retries=3"]
    #>   B["Analysis"]
    #>   C["Report"]
    #>   A --> B
    #>   B --> C
    #> ``` 
    #> ```mermaid
    #> graph TD
    #>   A["Initial Research | retries=3"]
    #>   B["Analysis"]
    #>   C["Report"]
    #>   A --> B
    #>   B --> C
    #> ```

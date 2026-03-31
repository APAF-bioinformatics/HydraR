## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
library(HydraR)

## ----logic_registry-----------------------------------------------------------
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

## ----factory------------------------------------------------------------------
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

## ----run----------------------------------------------------------------------
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
print(dag$nodes$B$params)

# Run the DAG
dag$run(initial_state = list(input = "test data"))

## ----plot---------------------------------------------------------------------
# Show all parameters
cat(dag$plot(details = TRUE))

# Filter to specific parameters
cat(dag$plot(details = TRUE, include_params = "retries"))


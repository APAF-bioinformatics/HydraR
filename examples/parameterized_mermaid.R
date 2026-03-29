# ==============================================================
# APAF Bioinformatics | HydraR | Examples
# File:        parameterized_mermaid.R
# Purpose:     Demonstrate bidirectional parameter passing in Mermaid
# ==============================================================

# Note: Run this with devtools::load_all() if the package is not installed
# devtools::load_all()

# 1. Define a DAG using Mermaid syntax with Parameters
# Parameters:
# - retries: integer
# - workdir: string path
# - verbose: logical
mermaid_spec <- "
graph TD
  A[\"Initial Research | retries=3 | workdir=./w1\"] --> B[\"Analysis | verbose=true\"]
  B --> C[\"Report | workdir=./output\"]
"

# 2. Define a Factory that knows how to use these parameters
# In a real app, you would dispatch to specialized node classes based on ID or params
node_factory <- function(id, label, params = list()) {
  
  # We create a simple subclass that prints its parameters during execution
  CustomNode <- R6::R6Class("CustomNode", 
    inherit = AgentNode,
    public = list(
      run = function(state) {
        param_str <- if(length(self$params) > 0) {
          paste(names(self$params), self$params, sep = "=", collapse = ", ")
        } else {
          "none"
        }
        message(sprintf("   [%s] Executing logic... (Params: %s)", self$id, param_str))
        list(status = "success", output = paste("Result from", self$id))
      }
    )
  )
  
  CustomNode$new(id, label, params)
}

# 3. Create DAG from Mermaid
message("--- Instantiating DAG from Parameterized Mermaid ---")
dag <- mermaid_to_dag(mermaid_spec, node_factory)

# 4. Verify Parameter Injection
message(sprintf("Node A Retries: %s (Type: %s)", dag$nodes$A$params$retries, typeof(dag$nodes$A$params$retries)))
message(sprintf("Node B Verbose: %s (Type: %s)", dag$nodes$B$params$verbose, typeof(dag$nodes$B$params$verbose)))
message(sprintf("Node C Workdir: %s", dag$nodes$C$params$workdir))

# 5. Run the DAG
message("\n--- Running DAG Workflow ---")
# Use a simple mock state
dag$run(initial_state = list(input = "test data"))

# 6. Plot the DAG back to Mermaid with Parameters (Details)
message("\n--- Round-Trip: Mermaid with Parameters (details = TRUE) ---")
mermaid_out <- dag$plot(details = TRUE)
cat(mermaid_out, "\n")

# 7. Plot with specific filter (Fine-tune control)
message("\n--- Round-Trip: Filtered parameters (retries only) ---")
cat(dag$plot(details = TRUE, include_params = "retries"), "\n")

# 8. Standard Plot (Clean view)
message("\n--- Standard Mermaid plot (details = FALSE) ---")
cat(dag$plot(details = FALSE), "\n")

message("\nDemo completed.")

# <!-- APAF Bioinformatics | parameterized_mermaid.R | Approved | 2026-03-29 -->

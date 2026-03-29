# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        round_trip_demo.R
# Purpose:     Demonstrates Mermaid -> R -> Status Plot workflow
# ==============================================================

library(HydraR)

# 1. Define a workflow using Mermaid syntax
# This workflow includes a decision point (Conditional Edge)
mermaid_spec <- "
graph TD
  Start[Initial Search] --> Summarize[Summarize Findings]
  Summarize --> Check[Check Quality]
  Check -- Test --> Publish[Final Report]
  Check -- Fail --> ReSearch[Deep Search]
  ReSearch --> Summarize
"

# 2. Define a Node Factory
# This maps Mermaid IDs/Labels to actual AgentNode objects
node_factory <- function(id, label) {
  if (id == "Check") {
    # A logic node that fails the first time but succeeds the second
    return(AgentLogicNode$new(id, function(state) {
      run_count <- state$get("check_runs") %||% 0
      state$set("check_runs", run_count + 1)
      
      if (run_count == 0) {
        cat("Quality check failed. Routing to ReSearch...\n")
        return(list(status = "success", output = FALSE))
      } else {
        cat("Quality check passed!\n")
        return(list(status = "success", output = TRUE))
      }
    }, label = label))
  }
  
  # Default: LLM Nodes (Mocked for this demo using a simple logic node)
  return(AgentLogicNode$new(id, function(state) {
    list(status = "success", output = paste("Result from", label))
  }, label = label))
}

# 3. Convert Mermaid to AgentDAG
cat("\n--- Parsing Mermaid into AgentDAG ---\n")
dag <- mermaid_to_dag(mermaid_spec, node_factory)

# 4. Map the conditional logic
# Note: from_mermaid adds edges, but test logic must currently be added manually
dag$add_conditional_edge("Check", test = function(out) out == TRUE, if_true = "Publish", if_false = "ReSearch")

# 5. Run the DAG
cat("\n--- Running the Workflow ---\n")
results <- dag$run(initial_state = list(check_runs = 0), max_steps = 10)

# 6. Generate the Status-Colored Mermaid String
cat("\n--- Generating Status Plot ---\n")
mermaid_colored <- dag$plot(status = TRUE)

# 7. (Optional) Render in RStudio
# if (requireNamespace("DiagrammeR", quietly = TRUE)) {
#   DiagrammeR::mermaid(mermaid_colored)
# }

cat("\nDemo completed. Check the Mermaid output above for class definitions and linkStyle.\n")

# <!-- APAF Bioinformatics | round_trip_demo.R | Approved | 2026-03-29 -->

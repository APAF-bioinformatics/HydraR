## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
library(HydraR)

## ----logic_registry-----------------------------------------------------------
round_trip_logic_registry <- list(
  # 1. Deterministic Logic Functions
  logic = list(
    Check = function(state, params = NULL) {
      # A logic node that fails the first time but succeeds the second
      run_count <- state$get("check_runs") %||% 0
      state$set("check_runs", run_count + 1)

      if (run_count == 0) {
        cat("Quality check failed. Routing to ReSearch...\n")
        return(list(status = "SUCCESS", output = FALSE))
      } else {
        cat("Quality check passed!\n")
        return(list(status = "SUCCESS", output = TRUE))
      }
    },
    Default = function(state, params = NULL) {
      list(status = "SUCCESS", output = paste("Result from", state$node_id))
    }
  )
)

## ----factory------------------------------------------------------------------
round_trip_node_factory <- function(id, label, params) {
  logic_fn <- round_trip_logic_registry$logic[[id]] %||% round_trip_logic_registry$logic$Default

  AgentLogicNode$new(
    id = id,
    label = label,
    logic_fn = logic_fn
  )
}

## ----dag----------------------------------------------------------------------
mermaid_spec <- "
graph TD
  Start[Initial Search] --> Summarize[Summarize Findings]
  Summarize --> Check[Check Quality]
  Check --> Publish[Final Report]
  Check --> ReSearch[Deep Search]
  ReSearch --> Summarize
"

# Create DAG from Mermaid
dag <- AgentDAG$from_mermaid(mermaid_spec, node_factory = round_trip_node_factory)

# Add the conditional logic for the quality loop
dag$add_conditional_edge(
  from = "Check",
  test = function(out) out == TRUE,
  if_true = "Publish",
  if_false = "ReSearch"
)

# Run the DAG
results <- dag$run(initial_state = list(check_runs = 0), max_steps = 10)

## ----plot---------------------------------------------------------------------
# Export status-colored Mermaid
mermaid_colored <- dag$plot(status = TRUE)

# Show the colored Mermaid syntax
cat(mermaid_colored)


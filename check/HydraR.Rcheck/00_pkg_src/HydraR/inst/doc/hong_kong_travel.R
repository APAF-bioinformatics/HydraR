## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----lib_load-----------------------------------------------------------------
library(HydraR)

## ----load_wf------------------------------------------------------------------
# Load everything from the external declarative source
wf <- load_workflow("hong_kong_travel.yml")

## ----dag_creation-------------------------------------------------------------
dag <- spawn_dag(wf, auto_node_factory())

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(dag$plot(type = "mermaid", details = TRUE))
cat("\n```\n")

## ----eval=TRUE----------------------------------------------------------------
# Register a checkpointer for durability
checkpointer <- DuckDBSaver$new(db_path = "travel_booking.duckdb")

# Run the orchestration using the state from YAML
results <- dag$run(initial_state = wf$initial_state, max_steps = 5, checkpointer = checkpointer)

# Display final itinerary (will be NULL if run without API keys)
cat(results$state$get("Planner"))


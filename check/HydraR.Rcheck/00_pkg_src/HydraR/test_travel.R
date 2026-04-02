library(devtools)
load_all(".")

# Ensure API Key is available
if (Sys.getenv("GEMINI_API_KEY") == "") {
  stop("Please set GEMINI_API_KEY environment variable.")
}

# 1. Load the workflow
wf <- load_workflow("vignettes/hong_kong_travel.yml")

# 2. Instantiate the DAG
dag <- mermaid_to_dag(wf$graph, auto_node_factory())
dag$set_start_node("Planner")
dag$compile()

# 3. Run the DAG
# Using a dummy initial state if needed, but wf has it
initial_state <- wf$initial_state
# Override with local config for testing if needed

results <- dag$run(initial_state = initial_state, max_steps = 5)

# 4. Display Results
cat("\n--- Execution Summary ---\n")
print(results$status)
cat("\n--- Node Results ---\n")
purrr::iwalk(results$results, function(res, id) {
  cat(sprintf("[%s] Status: %s\n", id, res$status))
})

# Display Planner Output
cat("\n--- Travel Itinerary ---\n")
cat(results$state$get("Planner"))

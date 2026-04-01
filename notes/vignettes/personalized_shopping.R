## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
shopping_logic_registry <- list(
  # 0. Initial Shopping Request
  initial_state = list(
    shopping_request = "I need a cool t-shirt for the weekend with graphic design."
  ),

  # 1. Agent Roles
  roles = list(
    Shopper = "You are a personalized shopping assistant. Based on the user's initial request and any feedback provide a specific product recommendation.",
    UserProxy = "You are a customer looking for a specific item. Review the recommended product and either say 'I'll buy it' or provide 'Modification Feedback'."
  ),

  # 2. Prompt Builders
  prompts = list(
    Shopper = function(state) {
      feedback_text <- if (!is.null(state$get("UserProxy"))) sprintf("\nUser Feedback: %s", state$get("UserProxy")) else ""
      sprintf("Original Request: %s%s\nOutput exactly a product name.", state$get("shopping_request"), feedback_text)
    },
    UserProxy = function(state) {
      sprintf("Recommended Item: %s\nOriginal Request: %s\nDecide if you like it or need something different.", state$get("Shopper"), state$get("shopping_request"))
    }
  )
)

## ----factory------------------------------------------------------------------
shopping_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (params[["driver"]] == "gemini") GeminiCLIDriver$new() else NULL

  AgentLLMNode$new(
    id = id,
    label = label,
    role = shopping_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = shopping_logic_registry$prompts[[id]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Shopper[Store Concierge | driver=gemini] --> UserProxy
  UserProxy[Customer Proxy | driver=gemini] -- Needs Modification --> Shopper
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = shopping_node_factory)

# Add conditional logic for the 'Buy' route (stop)
dag$add_conditional_edge(
  from = "UserProxy",
  test = function(out) grepl("buy it", out, ignore.case = TRUE),
  if_true = NULL, # Success!
  if_false = "Shopper" # Loop back
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(compiled_dag$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat("Starting Personalized Shopper...\n")
# 
# result <- compiled_dag$run(
#   initial_state = shopping_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# cat("\n--- SHOPPING RESULT ---\n")
# cat("Final Recommendation:", result$state$get("Shopper"), "\n")
# cat("User Feedback:", result$state$get("UserProxy"), "\n")


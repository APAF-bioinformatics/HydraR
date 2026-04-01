## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
hello_logic_registry <- list(
  # 0. Initial Configuration
  initial_state = list(),

  # 1. Deterministic Logic Functions
  logic = list(
    Validator = function(state, params) {
      guess <- tolower(trimws(state$get("Guesser")))
      is_valid <- (guess == "hello")
      list(status = "SUCCESS", output = list(valid = is_valid))
    }
  ),

  # 2. LLM Agent Roles
  roles = list(
    Guesser = "You are an agent trying to guess a specific word. Your task is to output exactly one word in lowercase."
  ),

  # 3. LLM Prompt Builders
  prompts = list(
    Guesser = function(state) {
      "Guess the secret greeting word."
    }
  )
)

## ----factory------------------------------------------------------------------
hello_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (!is.null(params[["driver"]]) && params[["driver"]] == "gemini") GeminiCLIDriver$new() else NULL

  if (id %in% names(hello_logic_registry$logic)) {
    # Create a deterministic Logic Node
    AgentLogicNode$new(
      id = id,
      label = label,
      logic_fn = hello_logic_registry$logic[[id]]
    )
  } else {
    # Create an agentic LLM Node
    AgentLLMNode$new(
      id = id,
      label = label,
      role = hello_logic_registry$roles[[id]],
      driver = driver_obj,
      prompt_builder = hello_logic_registry$prompts[[id]]
    )
  }
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Guesser[LLM Guesser | driver=gemini] --> Validator
  Validator[Greeting Validator] -- Incorrect --> Guesser
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = hello_node_factory)

# Add conditional logic for the guess loop
dag$add_conditional_edge(
  from = "Validator",
  test = function(out) isTRUE(out$valid),
  if_true = NULL, # Success!
  if_false = "Guesser" # Incorrect, try again
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(dag$compile()$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# final_state <- compiled_dag$run(
#   initial_state = hello_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# # View final results
# cat("Final Guess:", final_state$state$get("Guesser"), "\n")
# cat("Success Status:", final_state$state$get("valid"), "\n")


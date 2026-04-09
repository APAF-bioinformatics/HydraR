# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-hello_world_agent.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Hello World Agent Scenario
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

# Mock Driver for testing LLM nodes
MockDriver <- R6::R6Class("MockDriver",
  inherit = AgentDriver,
  public = list(
    last_prompt = NULL,
    response = "Mocked Response",
    initialize = function(id = "mock", response = "Mocked Response") {
      super$initialize(id)
      self$response <- response
    },
    call = function(prompt, ...) {
      self$last_prompt <- prompt
      return(self$response)
    }
  )
)

test_that("Hello World Guesser loop works", {
  driver <- MockDriver$new(response = "hi")

  dag <- AgentDAG$new()

  # 1. Guesser
  dag$add_node(AgentLLMNode$new(
    id = "Guesser",
    role = "Guesser",
    driver = driver,
    prompt_builder = function(state) "Guess word"
  ))

  # 2. Validator
  dag$add_node(AgentLogicNode$new(
    id = "Validator",
    logic_fn = function(state) {
      guess <- state$get("Guesser")
      if (guess == "hello") {
        list(status = "success", output = list(valid = TRUE))
      } else {
        # Update driver for next call
        driver$response <- "hello"
        list(status = "success", output = list(valid = FALSE))
      }
    }
  ))

  # Transitions
  dag$set_start_node("Guesser")
  dag$add_edge("Guesser", "Validator")

  dag$add_conditional_edge(
    from = "Validator",
    test = function(out) isTRUE(out$valid),
    if_true = NULL,
    if_false = "Guesser"
  )

  suppressWarnings(dag$compile())
  compiled_dag <- dag
  # Run the DAG
  result <- suppressWarnings(compiled_dag$run(initial_state = list(), max_steps = 10))
  # Assertions
  expect_equal(result$state$get("Guesser"), "hello")
  expect_true(result$state$get("valid"))
})

# <!-- APAF Bioinformatics | test-hello_world_agent.R | Approved | 2026-03-29 -->

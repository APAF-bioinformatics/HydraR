# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-personalized_shopping.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Personalized Shopping Scenario
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

test_that("Personalized Shopping loop works", {
  driver <- MockDriver$new(response = "Blue Shirt")

  dag <- AgentDAG$new()

  # 1. Shopper
  dag$add_node(AgentLLMNode$new(
    id = "Shopper",
    role = "Shopper",
    driver = driver,
    prompt_builder = function(state) paste("Find shirt like:", state$get("shopping_request"))
  ))

  # 2. UserProxy
  dag$add_node(AgentLLMNode$new(
    id = "UserProxy",
    role = "User",
    driver = driver,
    prompt_builder = function(state) paste("Review shirt:", state$get("Shopper"))
  ))

  # Transitions
  dag$set_start_node("Shopper")
  dag$add_edge("Shopper", "UserProxy")

  # Inject loop success on second iteration
  loop_count <- 0
  dag$add_conditional_edge(
    from = "UserProxy",
    test = function(out) {
      loop_count <<- loop_count + 1
      if (loop_count == 1) {
        driver$response <- "I'll buy it"
      }
      if (loop_count >= 2) {
        return(TRUE)
      }
      return(FALSE)
    },
    if_true = NULL,
    if_false = "Shopper"
  )

  capture_warnings(dag$compile())
  compiled_dag <- dag
# Run the DAG
result <- compiled_dag$run(
  initial_state = list(shopping_request = "Cool shirt"),
  max_steps = 10
)
  # Assertions
  expect_equal(loop_count, 2)
  expect_equal(result$state$get("UserProxy"), "I'll buy it")
})

# <!-- APAF Bioinformatics | test-personalized_shopping.R | Approved | 2026-03-29 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-hong_kong_travel.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Travel Planning (Hong Kong) Scenario
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

test_that("Hong Kong planning loop works", {
  # Mock driver initialized with a response missing 'Spaghetti House'
  driver <- MockDriver$new(response = "Visit Cheung Chau Island and enjoy local cuisine.")

  dag <- AgentDAG$new()

  # 1. Planner Node
  dag$add_node(AgentLLMNode$new(
    id = "TravelPlanner",
    role = "Travel Concierge",
    driver = driver,
    prompt_builder = function(state) "Plan trip"
  ))

  # 2. Auditor Node
  dag$add_node(AgentLogicNode$new(
    id = "Auditor",
    logic_fn = function(state) {
      itinerary <- state$get("TravelPlanner")
      must_include <- c("Cheung Chau Island", "Spaghetti House")

      found <- purrr::map_lgl(must_include, function(x) grepl(x, itinerary, ignore.case = TRUE))
      if (all(found)) {
        list(status = "success", output = list(validation_passed = TRUE))
      } else {
        # Update driver to include the missing item in the next call
        driver$response <- "Visit Cheung Chau Island and Spaghetti House!"
        list(status = "success", output = list(validation_passed = FALSE))
      }
    }
  ))

  # Transitions
  dag$set_start_node("TravelPlanner")
  dag$add_edge("TravelPlanner", "Auditor")

  dag$add_conditional_edge(
    from = "Auditor",
    test = function(out) isTRUE(out$validation_passed),
    if_true = NULL,
    if_false = "TravelPlanner"
  )

  capture_warnings(dag$compile())
  compiled_dag <- dag
  # Run the DAG
  result <- compiled_dag$run(initial_state = list(), max_steps = 5)
  # Assertions
  expect_true(grepl("Spaghetti House", result$state$get("TravelPlanner"), ignore.case = TRUE))
  expect_true(result$state$get("validation_passed"))
})

# <!-- APAF Bioinformatics | test-hong_kong_travel.R | Approved | 2026-03-29 -->

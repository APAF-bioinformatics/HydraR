# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-software_bug_assistant.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Software Bug Assistant Scenario
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

test_that("Software Bug Assistant loop works", {
  # Driver returns invalid patch then valid patch
  driver <- MockDriver$new(response = "Fix A")

  dag <- AgentDAG$new()

  # 1. Analyzer
  dag$add_node(AgentLLMNode$new(
    id = "Analyzer",
    role = "Debugger",
    driver = driver,
    prompt_builder = function(state) paste("Fix bug:", state$get("bug_report"))
  ))

  # 2. Tester
  dag$add_node(AgentLogicNode$new(
    id = "Tester",
    logic_fn = function(state) {
      patch <- state$get("Analyzer")
      if (grepl("is.null", patch)) {
        list(status = "success", output = list(tests_passed = TRUE))
      } else {
        # Update driver for next call
        driver$response <- "Use is.null(x)"
        list(status = "success", output = list(tests_passed = FALSE))
      }
    }
  ))

  # Transitions
  dag$set_start_node("Analyzer")
  dag$add_edge("Analyzer", "Tester")

  dag$add_conditional_edge(
    from = "Tester",
    test = function(out) isTRUE(out$tests_passed),
    if_true = NULL,
    if_false = "Analyzer"
  )

  capture_warnings(dag$compile())
  compiled_dag <- dag
  # Run the DAG
  result <- compiled_dag$run(
    initial_state = list(bug_report = "App crashes on startup"),
    max_steps = 10
  )
  # Assertions
  expect_equal(result$state$get("Analyzer"), "Use is.null(x)")
})

# <!-- APAF Bioinformatics | test-software_bug_assistant.R | Approved | 2026-03-29 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-story_teller.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Story Teller Scenario
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

test_that("Story Teller collaboration works", {
  driver <- MockDriver$new(response = "Story draft")

  dag <- AgentDAG$new()

  # 1. Writer
  dag$add_node(AgentLLMNode$new(
    id = "Writer",
    role = "Writer",
    driver = driver,
    prompt_builder = function(state) paste("Write story about:", state$get("story_prompt"))
  ))

  # 2. Reviewer
  dag$add_node(AgentLLMNode$new(
    id = "Reviewer",
    role = "Reviewer",
    driver = driver,
    prompt_builder = function(state) paste("Review story:", state$get("Writer"))
  ))

  # Transitions
  dag$set_start_node("Writer")
  dag$add_edge("Writer", "Reviewer")

  # Inject loop success on second iteration
  loop_count <- 0
  dag$add_conditional_edge(
    from = "Reviewer",
    test = function(out) {
      loop_count <<- loop_count + 1
      if (loop_count == 1) {
        driver$response <- "Approved"
      }
      if (loop_count >= 2) {
        return(TRUE)
      }
      return(FALSE)
    },
    if_true = NULL, # Stop
    if_false = "Writer" # Loop back
  )

  suppressWarnings(dag$compile())
  compiled_dag <- dag
  # Run the DAG
  result <- suppressWarnings(compiled_dag$run(
    initial_state = list(story_prompt = "A robot learning to cook."),
    max_steps = 10
  ))
  # Assertions
  expect_equal(loop_count, 2)
  expect_equal(result$state$get("Reviewer"), "Approved")
})

# <!-- APAF Bioinformatics | test-story_teller.R | Approved | 2026-03-29 -->

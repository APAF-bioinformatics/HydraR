# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-blog_writer.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Blog Writer Scenario
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

test_that("Blog Writer DAG loop works", {
  # Mock driver that starts with no "Approved" then returns it on the second call for Editor
  driver <- MockDriver$new(response = "Initial Content")

  dag <- AgentDAG$new()

  # 1. Outliner
  dag$add_node(AgentLLMNode$new(
    id = "Outliner",
    role = "Outliner",
    driver = driver,
    prompt_builder = function(state) paste("Outline:", state$get("blog_topic"))
  ))

  # 2. Drafter
  dag$add_node(AgentLLMNode$new(
    id = "Drafter",
    role = "Drafter",
    driver = driver,
    prompt_builder = function(state) paste("Draft based on:", state$get("Outliner"))
  ))

  # 3. Editor
  # We make the Editor LLM-based. For testing, it should eventually return "Approved".
  # We can mock the driver to return "Approved" if it sees "Draft based on" in the prompt for a certain number of times.
  # Or we just use a custom mock function if needed.

  editor_node <- AgentLLMNode$new(
    id = "Editor",
    role = "Editor",
    driver = driver,
    prompt_builder = function(state) paste("Review:", state$get("Drafter"))
  )
  dag$add_node(editor_node)

  # Transitions
  dag$set_start_node("Outliner")
  dag$add_edge("Outliner", "Drafter")
  dag$add_edge("Drafter", "Editor")

  # Inject loop success on second iteration
  loop_count <- 0
  dag$add_conditional_edge(
    from = "Editor",
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
    if_true = NULL,
    if_false = "Drafter"
  )

  capture_warnings(dag$compile())
  compiled_dag <- dag

  result <- compiled_dag$run(
    initial_state = list(blog_topic = "R Agents"),
    max_steps = 10
  )
  expect_equal(loop_count, 2)
  expect_equal(result$state$get("Editor"), "Approved")
})

# <!-- APAF Bioinformatics | test-blog_writer.R | Approved | 2026-03-29 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-academic_research.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Academic Research Scenario
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

test_that("Academic Research DAG processes via LLM nodes", {
  driver <- MockDriver$new(response = "Paper A: Content A. Paper B: Content B.")

  dag <- AgentDAG$new()

  # 1. Searcher
  dag$add_node(AgentLLMNode$new(
    id = "Searcher",
    role = "Researcher",
    driver = driver,
    prompt_builder = function(state) paste("Search for:", state$get("research_topic"))
  ))

  # 2. Summarizer
  dag$add_node(AgentLLMNode$new(
    id = "Summarizer",
    role = "Summarizer",
    driver = driver,
    prompt_builder = function(state) paste("Summarize:", state$get("Searcher"))
  ))

  # 3. Compiler
  dag$add_node(AgentLLMNode$new(
    id = "Compiler",
    role = "Compiler",
    driver = driver,
    prompt_builder = function(state) paste("Compile:", state$get("Summarizer"))
  ))

  # Transitions
  dag$set_start_node("Searcher")
  dag$add_edge("Searcher", "Summarizer")
  dag$add_edge("Summarizer", "Compiler")

  compiled_dag <- dag$compile()

  # Run the DAG
  result <- compiled_dag$run(
    initial_state = list(research_topic = "Genetics"),
    max_steps = 5
  )

  # Assertions
  expect_equal(result$state$get("Searcher"), "Paper A: Content A. Paper B: Content B.")
  expect_equal(result$state$get("Summarizer"), "Paper A: Content A. Paper B: Content B.")
  expect_equal(result$state$get("Compiler"), "Paper A: Content A. Paper B: Content B.")
  expect_match(driver$last_prompt, "Compile: Paper A: Content A. Paper B: Content B.")
})

# <!-- APAF Bioinformatics | test-academic_research.R | Approved | 2026-03-29 -->

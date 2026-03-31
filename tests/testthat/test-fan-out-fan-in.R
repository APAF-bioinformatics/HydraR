# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-fan-out-fan-in.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Fan-Out and Fan-In Synthesis Scenario
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

# Mock Driver for testing LLM nodes
MockFanOutDriver <- R6::R6Class("MockFanOutDriver",
  inherit = AgentDriver,
  public = list(
    call = function(prompt, ...) {
      if (grepl("creative director", prompt)) {
        return("The cybernetic cat enters the hidden city.")
      } else if (grepl("action-thriller", prompt)) {
        return("Explosions in the neon alleyway!")
      } else if (grepl("mystery writer", prompt)) {
        return("Who left this cryptic holodisk?")
      } else if (grepl("romance writer", prompt)) {
        return("The cat shared a tender moment with a drone.")
      } else if (grepl("master editor", prompt)) {
        return("The final story: Action, Mystery, and Romance combined.")
      }
      return("Default mock response")
    }
  )
)

test_that("Fan-Out Fan-In DAG executes correctly", {
  story_logic_registry <- list(
    roles = list(
      director = "You are the creative director setting the stage.",
      writer_action = "You are an action-thriller writer. Write a short, fast-paced scene.",
      writer_mystery = "You are a mystery writer. Write a short, suspenseful scene.",
      writer_romance = "You are a romance writer. Write a short, emotional scene.",
      editor = "You are the master editor. Combine the scenes into a cohesive short story."
    ),
    prompts = list(
      director = function(state) {
        sprintf("Expand slightly on this premise: %s", state$get("premise"))
      },
      writer_action = function(state) {
        sprintf("Based on the director's vision: %s\nWrite an action scene.", state$get("director"))
      },
      writer_mystery = function(state) {
        sprintf("Based on the director's vision: %s\nWrite a mystery scene.", state$get("director"))
      },
      writer_romance = function(state) {
        sprintf("Based on the director's vision: %s\nWrite a romantic or emotional scene.", state$get("director"))
      },
      editor = function(state) {
        sprintf(
          "Synthesize these three scenes into one short story:\n\nAction: %s\n\nMystery: %s\n\nRomance: %s",
          state$get("writer_action"),
          state$get("writer_mystery"),
          state$get("writer_romance")
        )
      }
    )
  )

  # Factory
  story_node_factory <- function(id, label, params) {
    AgentLLMNode$new(
      id = id,
      label = label,
      role = story_logic_registry$roles[[id]],
      driver = MockFanOutDriver$new(),
      prompt_builder = story_logic_registry$prompts[[id]]
    )
  }

  mermaid_graph <- "
  graph TD
    director[Director] --> writer_action[Action Writer]
    director --> writer_mystery[Mystery Writer]
    director --> writer_romance[Romance Writer]

    writer_action --> editor[Master Editor]
    writer_mystery --> editor
    writer_romance --> editor
  "

  # Create and compile DAG
  dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = story_node_factory)
  expect_silent(dag$compile())

  # Ensure the graph has the right structure
  expect_true(igraph::is_dag(dag$graph))
  expect_equal(length(dag$nodes), 5)
  expect_equal(length(igraph::E(dag$graph)), 6) # 3 fan-out + 3 fan-in edges

  # Run DAG
  initial_state <- list(premise = "A cybernetic cat discovers a hidden underground city.")

  # Suppressing print messages from DAG execution
  capture.output({
    result <- dag$run(initial_state = initial_state)
  })

  # Assertions
  expect_equal(result$status, "completed")
  expect_equal(result$state$get("director"), "The cybernetic cat enters the hidden city.")
  expect_equal(result$state$get("writer_action"), "Explosions in the neon alleyway!")
  expect_equal(result$state$get("writer_mystery"), "Who left this cryptic holodisk?")
  expect_equal(result$state$get("writer_romance"), "The cat shared a tender moment with a drone.")
  expect_equal(result$state$get("editor"), "The final story: Action, Mystery, and Romance combined.")

  # Ensure execution order: director -> writers -> editor
  traces <- result$trace_log
  expect_true(!is.null(traces))

  # The editor should be the last node executed
  executed_nodes <- purrr::map_chr(traces, ~ .x$node)
  expect_equal(tail(executed_nodes, 1), "editor")
  expect_equal(head(executed_nodes, 1), "director")
})

# <!-- APAF Bioinformatics | test-fan-out-fan-in.R | Approved | 2026-03-31 -->

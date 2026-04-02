# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-coverage_validation.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for Graph Validation coverage
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("Graph validation detects circular dependencies", {
  dag <- AgentDAG$new()
  dag$add_node(AgentNode$new("A"))
  dag$add_node(AgentNode$new("B"))
  dag$add_edge("A", "B")
  dag$add_edge("B", "A")

  expect_error(dag$compile(), "Circular dependency detected")
})

test_that("Graph validation detects undefined nodes in edges", {
  dag <- AgentDAG$new()
  dag$add_node(AgentNode$new("A"))
  dag$add_edge("A", "UNDEFINED")

  expect_error(dag$compile(), "Undefined node\\(s\\) referenced in edges: UNDEFINED")
})

test_that("Graph validation handles multiple start nodes", {
  dag <- AgentDAG$new()
  dag$add_node(AgentNode$new("A"))
  dag$add_node(AgentNode$new("B"))
  # No edges -> both are possible start nodes
  expect_warning(dag$compile(), "Multiple potential start nodes found")
})

test_that("Graph validation identifies terminals", {
  dag <- AgentDAG$new()
  dag$add_node(AgentNode$new("A"))
  dag$add_node(AgentNode$new("B"))
  dag$add_edge("A", "B")
  dag$compile()
  # B is terminal
  expect_equal(dag$get_terminal_nodes(), "B")
})

# <!-- APAF Bioinformatics | test-coverage_validation.R | Approved | 2026-03-31 -->

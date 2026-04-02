# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-coverage_mermaid.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for Mermaid parser coverage
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("parse_mermaid handles empty input", {
  res <- parse_mermaid(NULL)
  expect_equal(nrow(res$nodes), 0)
  res <- parse_mermaid("")
  expect_equal(nrow(res$nodes), 0)
})

test_that("parse_mermaid handles various bracket types and labels", {
  mermaid <- "graph TD
    A[Square Bracket]
    B(Round Bracket)
    C{Curly Bracket}
    D>Flag Bracket]
  "
  res <- parse_mermaid(mermaid)
  expect_equal(nrow(res$nodes), 4)
  expect_equal(res$nodes$label[res$nodes$id == "A"], "Square Bracket")
  expect_equal(res$nodes$label[res$nodes$id == "D"], "Flag Bracket")
})

test_that("parse_mermaid extracts parameters from labels", {
  mermaid <- "graph TD
    NodeA[My Agent | role=planner | model=gpt4]
  "
  res <- parse_mermaid(mermaid)
  params <- res$nodes$params[[1]]
  expect_equal(params[["role"]], "planner")
  expect_equal(params[["model"]], "gpt4")
  expect_equal(res$nodes$label[1], "My Agent")
})

test_that("parse_mermaid handles edge labels and multi-step chains", {
  mermaid <- "graph TD
    A -- yes --> B
    B --> |no| C
    C --> D --> E
  "
  res <- parse_mermaid(mermaid)
  expect_equal(nrow(res$edges), 4)
  expect_equal(res$edges$label[res$edges$from == "A"], "yes")
  expect_equal(res$edges$label[res$edges$from == "B"], "no")
  # Multi-chain check
  expect_true(any(res$edges$from == "C" & res$edges$to == "D"))
  expect_true(any(res$edges$from == "D" & res$edges$to == "E"))
})

test_that("parse_mermaid ignores code block guards and headers", {
  mermaid <- "```mermaid\nflowchart TD\n  START --> END\n```"
  res <- parse_mermaid(mermaid)
  expect_equal(nrow(res$nodes), 2)
  expect_true("START" %in% res$nodes$id)
})

test_that("mermaid_to_dag integration works", {
  mermaid <- "graph TD\n  Node1 --> Node2"
  dag <- mermaid_to_dag(mermaid)
  expect_true(inherits(dag, "AgentDAG"))
  expect_setequal(names(dag$nodes), c("Node1", "Node2"))
})

# <!-- APAF Bioinformatics | test-coverage_mermaid.R | Approved | 2026-03-31 -->

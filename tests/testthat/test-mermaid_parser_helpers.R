# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-mermaid_parser_helpers.R
# Purpose:     Unit tests for internal Mermaid parser helpers
# ==============================================================

library(testthat)
library(HydraR)

# Helper for testing internal functions
hp <- function(name) {
  getFromNamespace(name, "HydraR")
}

test_that("clean_mermaid_lines handles various inputs", {
  clean_mermaid_lines <- hp("clean_mermaid_lines")

  # Basic case
  expect_equal(clean_mermaid_lines("graph TD\nA --> B\n\n  C --> D  "), c("A --> B", "C --> D"))

  # Guards and headers
  mermaid <- "
  ```mermaid
  flowchart LR
    A --> B
  ```
  "
  expect_equal(clean_mermaid_lines(mermaid), "A --> B")

  # Null/Empty
  expect_equal(clean_mermaid_lines(NULL), character(0))
  expect_equal(clean_mermaid_lines(""), character(0))
})

test_that("extract_edge_and_node_strings handles arrow variations", {
  extract_edge_and_node_strings <- hp("extract_edge_and_node_strings")

  # Standard -->
  res1 <- extract_edge_and_node_strings("A --> B")
  expect_equal(res1$node_strings, c("A", "B"))
  expect_equal(res1$edge_labels, "")

  # Arrow with label in pipes
  res2 <- extract_edge_and_node_strings("A -->|test| B")
  expect_equal(res2$node_strings, c("A", "B"))
  expect_equal(res2$edge_labels, "test")

  # Arrow with label in dashes
  res3 <- extract_edge_and_node_strings("A -- label --> B")
  expect_equal(res3$node_strings, c("A", "B"))
  expect_equal(res3$edge_labels, "label")

  # Multiple arrows
  res4 <- extract_edge_and_node_strings("A -->|1| B -- 2 --> C")
  expect_equal(res4$node_strings, c("A", "B", "C"))
  expect_equal(res4$edge_labels, c("1", "2"))

  # No arrows
  res5 <- extract_edge_and_node_strings("A[Only Node]")
  expect_equal(res5$node_strings, "A[Only Node]")
  expect_equal(res5$edge_labels, character(0))
})

test_that("extract_params handles pipeline parameters", {
  extract_params <- hp("extract_params")

  # Label without params
  res1 <- extract_params("Normal Label")
  expect_equal(res1$label, "Normal Label")
  expect_equal(res1$params, list())

  # Single parameter
  res2 <- extract_params("Task | priority=high")
  expect_equal(res2$label, "Task")
  expect_equal(res2$params$priority, "high")

  # Multiple parameters and coercion
  res3 <- extract_params("Node | count=10 | active=true | meta=null | flag=na")
  expect_equal(res3$label, "Node")
  expect_equal(res3$params$count, 10)
  expect_equal(res3$params$active, TRUE)
  expect_null(res3$params$meta)
  expect_true(is.na(res3$params$flag))

  # Case insensitivity for bools/null
  res4 <- extract_params("Node | bit=FALSE | ref=NULL")
  expect_equal(res4$params$bit, FALSE)
  expect_null(res4$params$ref)
})

test_that("parse_node_string handles bracket types and quotes", {
  parse_node_string <- hp("parse_node_string")

  # Standard brackets
  expect_equal(parse_node_string("A[Label]"), list(id = "A", label_text = "Label"))

  # Parentheses/Circles
  expect_equal(parse_node_string("B(Round)"), list(id = "B", label_text = "Round"))

  # Braces/Rhombus
  expect_equal(parse_node_string("C{Decision}"), list(id = "C", label_text = "Decision"))

  # Flag
  expect_equal(parse_node_string("D>Flag]"), list(id = "D", label_text = "Flag"))

  # Quoted labels
  expect_equal(parse_node_string("E[\"Complex Label\"]"), list(id = "E", label_text = "Complex Label"))

  # Simple ID
  expect_equal(parse_node_string("SimpleID"), list(id = "SimpleID", label_text = "SimpleID"))
})

test_that("build_nodes_df handles deduplication and prioritization", {
  build_nodes_df <- hp("build_nodes_df")

  all_nodes <- list(
    list(id = "A", label = "A", params = list()),
    list(id = "A", label = "Explicit A", params = list()), # Should prioritize explicit label
    list(id = "B", label = "B", params = list(k = 1)),     # Has params
    list(id = "B", label = "B", params = list())           # Should prioritize the one with params
  )

  df <- build_nodes_df(all_nodes)
  expect_equal(nrow(df), 2)
  expect_equal(subset(df, id == "A")$label, "Explicit A")
  expect_equal(subset(df, id == "B")$params[[1]], list(k = 1))
})

test_that("build_edges_df handles empty and framing", {
  build_edges_df <- hp("build_edges_df")

  # Normal case
  edges <- list(
    list(from = "A", to = "B", label = "yes"),
    list(from = "B", to = "C", label = "")
  )
  df <- build_edges_df(edges)
  expect_equal(nrow(df), 2)
  expect_equal(colnames(df), c("from", "to", "label"))

  # Empty case
  df_empty <- build_edges_df(list())
  expect_equal(nrow(df_empty), 0)
  expect_true(all(c("from", "to", "label") %in% colnames(df_empty)))
})

# <!-- APAF Bioinformatics | test-mermaid_parser_helpers.R | Approved | 2026-03-31 -->

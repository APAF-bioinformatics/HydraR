library(testthat)
library(HydraR)

# Testing Modular Functions

test_that("clean_mermaid_lines cleans properly", {
  # We test the internal function via namespace or triple colon if exported/unexported
  # Since it's internal, we will use HydraR:::clean_mermaid_lines if needed,
  # or test it implicitly through parse_mermaid if preferred. Let's use `:::` for direct unit tests.

  clean_mermaid_lines <- HydraR:::clean_mermaid_lines

  # Empty/null cases
  expect_equal(clean_mermaid_lines(""), character(0))
  expect_equal(clean_mermaid_lines(NULL), character(0))

  # Normal cases
  raw_mermaid <- "```mermaid\ngraph TD\n  A --> B\n  \n```"
  cleaned <- clean_mermaid_lines(raw_mermaid)
  expect_equal(cleaned, c("A --> B"))
})

test_that("extract_edge_and_node_strings extracts correctly", {
  extract_edge_and_node_strings <- HydraR:::extract_edge_and_node_strings

  # Standard arrow
  res <- extract_edge_and_node_strings("A --> B")
  expect_equal(res$parts, c("A", "B"))
  expect_equal(res$edge_labels, "")

  # Pipe label
  res2 <- extract_edge_and_node_strings("A -->|label| B")
  expect_equal(res2$parts, c("A", "B"))
  expect_equal(res2$edge_labels, "label")

  # Dash label
  res3 <- extract_edge_and_node_strings("A -- label --> B")
  expect_equal(res3$parts, c("A", "B"))
  expect_equal(res3$edge_labels, "label")

  # Multi-edge
  res4 <- extract_edge_and_node_strings("A --> B --> C")
  expect_equal(res4$parts, c("A", "B", "C"))
  expect_equal(res4$edge_labels, c("", ""))
})

test_that("extract_params handles various coercion cases", {
  extract_params <- HydraR:::extract_params

  # No params
  expect_equal(extract_params("Label")$params, list())
  expect_equal(extract_params("Label")$label, "Label")

  # With params
  res <- extract_params("Label | key1=value1 | key2=123 | key3=true | key4=null | key5=NA")
  expect_equal(res$label, "Label")
  expect_equal(res$params$key1, "value1")
  expect_equal(res$params$key2, 123)
  expect_equal(res$params$key3, TRUE)
  expect_null(res$params$key4)
  expect_true(is.na(res$params$key5))
})

test_that("parse_node_string parses different bracket types", {
  parse_node_string <- HydraR:::parse_node_string

  # ID only
  expect_equal(parse_node_string("A")$id, "A")
  expect_equal(parse_node_string("A")$label, "A")

  # []
  expect_equal(parse_node_string("A[Label]")$id, "A")
  expect_equal(parse_node_string("A[Label]")$label, "Label")

  # ()
  expect_equal(parse_node_string("B(Label)")$id, "B")
  expect_equal(parse_node_string("B(Label)")$label, "Label")

  # {}
  expect_equal(parse_node_string("C{Label}")$id, "C")
  expect_equal(parse_node_string("C{Label}")$label, "Label")

  # >]
  expect_equal(parse_node_string("D>Label]")$id, "D")
  expect_equal(parse_node_string("D>Label]")$label, "Label")

  # Quotes
  expect_equal(parse_node_string("E[\"Label Text\"]")$label, "Label Text")
})

test_that("build_nodes_df and build_edges_df work correctly", {
  build_nodes_df <- HydraR:::build_nodes_df
  build_edges_df <- HydraR:::build_edges_df

  raw_nodes <- list(
    list(id = "A", label = "A", params = list()),
    list(id = "A", label = "Node A", params = list(k = 1)),
    list(id = "B", label = "Node B", params = list())
  )

  nodes_df <- build_nodes_df(raw_nodes)
  expect_equal(nrow(nodes_df), 2)
  expect_equal(nodes_df$id, c("A", "B"))
  expect_equal(nodes_df$label, c("Node A", "Node B"))
  expect_equal(nodes_df$params[[1]]$k, 1)

  raw_edges <- list(
    list(from = "A", to = "B", label = "label1")
  )
  edges_df <- build_edges_df(raw_edges)
  expect_equal(nrow(edges_df), 1)
  expect_equal(edges_df$from, "A")
  expect_equal(edges_df$to, "B")
  expect_equal(edges_df$label, "label1")

  # Empty edges
  empty_edges <- build_edges_df(list())
  expect_equal(nrow(empty_edges), 0)
})

# Original Integration Tests

test_that("Regex Flowchart Parser extracts nodes and edges", {
  mermaid <- "
    graph TD
      A[\"Node A\"] --> B[\"Node B\"]
      B --> C[\"Node C\"]
      C --> D
    "
  parsed <- parse_mermaid(mermaid)

  expect_equal(length(parsed$nodes), 4)
  expect_equal(nrow(parsed$edges), 3)

  # Check labels
  get_label <- function(nodes, target_id) {
    for (n in nodes) {
      if (identical(n$id, target_id)) return(n$label)
    }
    return(NULL)
  }
  expect_equal(get_label(parsed$nodes, "A"), "Node A")
  expect_equal(get_label(parsed$nodes, "B"), "Node B")
  expect_equal(get_label(parsed$nodes, "C"), "Node C")
  expect_equal(get_label(parsed$nodes, "D"), "D")
})

test_that("Conditional edges are parsed", {
  mermaid <- "
    graph TD
      A --> B
      B -- test_ok --> C
      B -- test_fail --> D
    "
  parsed <- parse_mermaid(mermaid)
  expect_equal(nrow(parsed$edges), 3)

  # Check edge labels
  expect_equal(subset(parsed$edges, from == "B" & to == "C")$label, "test_ok")
  expect_equal(subset(parsed$edges, from == "B" & to == "D")$label, "test_fail")
})

# <!-- APAF Bioinformatics | test-mermaid_parser.R | Approved | 2026-03-29 -->

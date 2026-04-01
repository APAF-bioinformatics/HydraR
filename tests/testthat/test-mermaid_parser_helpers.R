library(testthat)
library(HydraR)

# Access internal functions via ::: if needed, or by environment
hp <- function(name) {
  get(name, envir = asNamespace("HydraR"))
}

test_that("clean_mermaid_lines works", {
  clean_mermaid_lines <- hp("clean_mermaid_lines")

  mermaid <- "
graph TD
  A --> B
  %% Comment
  C --> D
"
  res <- clean_mermaid_lines(mermaid)
  expect_equal(length(res), 2)
  expect_true(all(grepl("-->", res)))
  expect_false(any(grepl("graph", res)))
})

test_that("extract_edge_and_node_strings handles labels", {
  extract_edge_and_node_strings <- hp("extract_edge_and_node_strings")

  # Standard edge
  line1 <- "A --> B"
  res1 <- extract_edge_and_node_strings(line1)
  expect_equal(res1$parts, c("A", "B"))
  expect_equal(res1$edge_labels, "")

  # Edge with label
  line2 <- "A -- Label --> B"
  res2 <- extract_edge_and_node_strings(line2)
  expect_equal(res2$parts, c("A", "B"))
  expect_equal(res2$edge_labels, "Label")

  # Multiple edges
  line3 <- "A --> B -- Next --> C"
  res3 <- extract_edge_and_node_strings(line3)
  expect_equal(res3$parts, c("A", "B", "C"))
  expect_equal(res3$edge_labels, c("", "Next"))
})

test_that("extract_params handles pipe-delimited parameters", {
  extract_params <- hp("extract_params")

  # No parameters
  res1 <- extract_params("Job A")
  expect_equal(res1$label, "Job A")
  expect_equal(res1$params, list())

  # Single parameter
  res2 <- extract_params("Task | priority=high")
  expect_equal(res2$label, "Task")
  expect_equal(res2$params[["priority"]], "high")

  # Multiple parameters and coercion
  res3 <- extract_params("Node | count=10 | active=true | meta=null | flag=na")
  expect_equal(res3$label, "Node")
  expect_equal(res3$params[["count"]], 10)
  expect_equal(res3$params[["active"]], TRUE)
  expect_null(res3$params[["meta"]])
  expect_true(is.na(res3$params[["flag"]]))

  # Case insensitivity for bools/null
  res4 <- extract_params("Node | bit=FALSE | ref=NULL")
  expect_equal(res4$params[["bit"]], FALSE)
  expect_null(res4$params[["ref"]])
})

test_that("parse_node_string handles bracket types and quotes", {
  parse_node_string <- hp("parse_node_string")

  # Standard brackets
  expect_equal(parse_node_string("A[Label]"), list(id = "A", label = "Label", params = list()))

  # Parentheses/Circles
  expect_equal(parse_node_string("B(Round)"), list(id = "B", label = "Round", params = list()))

  # Braces/Rhombus
  expect_equal(parse_node_string("C{Decision}"), list(id = "C", label = "Decision", params = list()))

  # Flag
  expect_equal(parse_node_string("D>Flag]"), list(id = "D", label = "Flag", params = list()))

  # Quoted labels
  expect_equal(parse_node_string("E[\"Complex Label\"]"), list(id = "E", label = "Complex Label", params = list()))
})

test_that("build_nodes_df deduplicates and merges labels/params", {
  build_nodes_df <- hp("build_nodes_df")

  nodes_raw <- list(
    list(id = "A", label = "A", params = list(priority = "high")),
    list(id = "B", label = "B", params = list(count = 5)),
    list(id = "A", label = "Node A", params = list())
  )

  df <- build_nodes_df(nodes_raw)
  expect_equal(nrow(df), 2)
  expect_true("A" %in% df$id)
  expect_true("B" %in% df$id)

  # Verify parameter list-column
  if (nrow(df) == 2) {
    # Sort for predictability
    df <- df[order(df$id), ]
    expect_equal(df$params[[1]][["priority"]], "high")
    expect_equal(df$params[[2]][["count"]], 5)
  }
})

test_that("Full parse_mermaid flow", {
  mermaid <- "
graph TD
  A[Node A | role=runner] --> B -- \"Ok\" --> C(Node C)
  B --> D{Fail}
"
  res <- parse_mermaid(mermaid)

  expect_s3_class(res$nodes, "data.frame")
  expect_s3_class(res$edges, "data.frame")

  expect_equal(nrow(res$nodes), 4)
  expect_equal(nrow(res$edges), 3)

  # Check specific node data
  node_a <- res$nodes[res$nodes$id == "A", ]
  expect_equal(node_a$label, "Node A")
  expect_equal(node_a$params[[1]][["role"]], "runner")

  # Check edge labels
  edge_bc <- res$edges[res$edges$from == "B" & res$edges$to == "C", ]
  expect_equal(edge_bc$label, "Ok")
})

# <!-- APAF Bioinformatics | test-mermaid_parser_helpers.R | Approved | 2026-03-31 -->

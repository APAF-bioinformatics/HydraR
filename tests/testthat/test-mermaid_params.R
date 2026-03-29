library(testthat)
# Note: Use devtools::load_all() or library(HydraR) in a real test environment
# Here we assume the package is available or we are running within devtools context

test_that("Mermaid parser extracts parameters correctly", {
  mermaid <- "graph TD\n  A[\"Node A | retries=3 | isolation=true\"] --> B"
  parsed <- parse_mermaid(mermaid)
  
  node_a <- subset(parsed$nodes, id == "A")
  expect_equal(node_a$label, "Node A")
  expect_equal(node_a$params[[1]]$retries, 3)
  expect_equal(node_a$params[[1]]$isolation, TRUE)
})

test_that("Mermaid parser handles edge cases", {
  # 1. Special characters in paths
  m1 <- "graph TD\n  A[\"Repo | path=/Users/test/repo\"]"
  p1 <- parse_mermaid(m1)
  expect_equal(p1$nodes$params[[1]]$path, "/Users/test/repo")
  
  # 2. Spaces around equals
  m2 <- "graph TD\n  A[\"Node | key = value \"]"
  p2 <- parse_mermaid(m2)
  expect_equal(p2$nodes$params[[1]]$key, "value")
  
  # 3. Brackets in values
  m3 <- "graph TD\n  A[\"Regex | pattern=[A-Z]+\"]"
  p3 <- parse_mermaid(m3)
  expect_equal(p3$nodes$params[[1]]$pattern, "[A-Z]+")
  
  # 4. Multiple pipes and empty values
  m4 <- "graph TD\n  A[\"Node | k1=v1 | k2= \"]"
  p4 <- parse_mermaid(m4)
  expect_equal(p4$nodes$params[[1]]$k1, "v1")
  expect_equal(p4$nodes$params[[1]]$k2, "")
})

test_that("Bidirectional parameter round-trip works", {
  # Mock subclass for testing run-less nodes
  TestNode <- R6::R6Class("TestNode", inherit = AgentNode, public = list(run = function(s) list()))

  dag <- AgentDAG$new()
  
  # Mock factory that preserves params
  factory <- function(id, label, params = list()) {
    TestNode$new(id, label, params)
  }
  
  mermaid_in <- "graph TD\n  A[\"Start | retries=5\"] --> B[\"End | status=final \"]"
  dag$from_mermaid(mermaid_in, factory)
  
  expect_equal(dag$nodes$A$params$retries, 5)
  expect_equal(dag$nodes$B$params$status, "final")
  
  # Plot with details
  mermaid_out <- dag$plot(details = TRUE)
  expect_match(mermaid_out, "A\\[\"Start \\| retries=5\"\\]")
  expect_match(mermaid_out, "B\\[\"End \\| status=final\"\\]")
  
  # Plot with filtering
  mermaid_filtered <- dag$plot(details = TRUE, include_params = "retries")
  expect_match(mermaid_filtered, "Start \\| retries=5")
  expect_false(grepl("status=final", mermaid_filtered))

  # 3. Edge label round-trip
  m_edge <- "graph TD\n  A -- Success --> B"
  dag2 <- AgentDAG$new()
  dag2$from_mermaid(m_edge, factory)
  p_edge <- dag2$plot()
  expect_match(p_edge, "A -- Success --> B")
})

test_that("Edge label control works in plot", {
  TestNode <- R6::R6Class("TestNode", inherit = AgentNode, public = list(run = function(s) list()))
  dag <- AgentDAG$new()
  n1 <- TestNode$new("A", "Start")
  n2 <- TestNode$new("B", "End")
  dag$add_node(n1)$add_node(n2)
  dag$add_edge("A", "B", label = "Success")
  
  # Default (On)
  expect_match(dag$plot(), "A -- Success --> B")
  
  # Off
  p_off <- dag$plot(show_edge_labels = FALSE)
  expect_match(p_off, "A --> B")
  expect_false(grepl("Success", p_off))
})

# <!-- APAF Bioinformatics | test-mermaid_params.R | Approved | 2026-03-29 -->

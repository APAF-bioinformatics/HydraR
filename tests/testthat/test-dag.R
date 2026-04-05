library(testthat)
library(HydraR)

test_that("AgentDAG Mermaid plotting works", {
  dag <- AgentDAG$new()
  dag$add_node(AgentLogicNode$new("node1", function(state) list(status = "success")))
  dag$add_node(AgentLogicNode$new("node2", function(state) list(status = "success")))
  dag$add_edge("node1", "node2")

  # Capture Mermaid output
  output <- capture.output({
    invisible(dag$plot(type = "mermaid"))
  })

  mermaid_str <- paste(output, collapse = "\n")

  expect_match(mermaid_str, "```mermaid")
  expect_match(mermaid_str, "graph TD")
  expect_match(mermaid_str, "node1\\[\"node1\"\\]")
  expect_match(mermaid_str, "node2\\[\"node2\"\\]")
  expect_match(mermaid_str, "node1 --> node2")
})

test_that("AgentDAG compile detects unreachable nodes and cycles", {
  dag <- AgentDAG$new()
  dag$add_node(AgentLogicNode$new("node1", function(state) list(status = "success")))
  dag$add_node(AgentLogicNode$new("node2", function(state) list(status = "success")))
  dag$add_node(AgentLogicNode$new("node3", function(state) list(status = "success")))

  # node2 -> node3 -> node2 (cycle)
  dag$add_edge("node2", "node3")
  dag$add_edge("node3", "node2")

  # node1 is a start node, node2 and node3 are unreachable from start node
  dag$set_start_node("node1")

  # Compile should throw an error about the cycle
  expect_error(dag$compile(), "Circular dependency detected")
})

test_that("AgentDAG logic node captures error context", {
  dag <- AgentDAG$new()
  # In HydraR, AgentLogicNode doesn't yet have the stack trace capture
  # of the RforRobot version, but we can test basic error handling.
  dag$add_node(AgentLogicNode$new("fail_node", function(state) {
    stop("Deep logic failure")
  }))

  state <- AgentState$new(list(input = "test"))
  dag$run(state)

  log_entry <- dag$trace_log[[1]]
  expect_equal(log_entry$status, "failed")
  expect_match(log_entry$error, "Deep logic failure")
})

test_that("AgentDAG Mermaid plotting uses labels", {
  dag <- AgentDAG$new()
  # Using custom labels
  node1 <- AgentLogicNode$new("node1", function(state) list(), label = "Start Process")
  node2 <- AgentLogicNode$new("node2", function(state) list(), label = "End Process")
  dag$add_node(node1)
  dag$add_node(node2)
  dag$add_edge("node1", "node2")

  output <- capture.output({
    invisible(dag$plot(type = "mermaid"))
  })
  mermaid_str <- paste(output, collapse = "\n")

  expect_match(mermaid_str, "node1\\[\"Start Process\"\\]")
  expect_match(mermaid_str, "node2\\[\"End Process\"\\]")
})

test_that("AgentDAG compile detects undefined nodes", {
  dag <- AgentDAG$new()
  dag$add_node(AgentLogicNode$new("node1", function(state) list()))

  # Reference an undefined node 'node2' in an edge
  dag$add_edge("node1", "node2")

  expect_error(dag$compile(), "Undefined node\\(s\\) referenced in edges: node2")
})

# <!-- APAF Bioinformatics | test-dag.R | Approved | 2026-03-29 -->

test_that("AgentDAG supports multiple explicitly set start nodes", {
  dag <- AgentDAG$new()
  dag$add_node(AgentNode$new("A"))
  dag$add_node(AgentNode$new("B"))
  dag$add_node(AgentNode$new("C"))
  dag$add_edge("A", "C")
  dag$add_edge("B", "C")

  # A and B are both roots. Setting both as start should silence warnings in compile.
  dag$set_start_node(c("A", "B"))
  expect_no_warning(dag$compile())

  # Setting only one should warn about the other being unreachable
  dag$set_start_node("A")
  expect_warning(dag$compile(), "Nodes unreachable from start node\\(s\\) \\[A\\]: B")
})

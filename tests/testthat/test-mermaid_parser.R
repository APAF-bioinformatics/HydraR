library(testthat)
library(HydraR)

context("Mermaid Parser")

test_that("Regex Flowchart Parser extracts nodes and edges", {
    mermaid <- "
    graph TD
      A[\"Node A\"] --> B[\"Node B\"]
      B --> C[\"Node C\"]
      C --> D
    "
    # Expected behavior:
    # nodes: A, B, C, D
    # edges: (A, B), (B, C), (C, D)
    
    # This will be implemented in R/mermaid_parser.R
    # parsed <- parse_mermaid(mermaid)
    # expect_equal(length(parsed$nodes), 4)
    # expect_equal(nrow(parsed$edges), 3)
})

test_that("Conditional edges are parsed", {
    mermaid <- "
    graph TD
      A --> B
      B -- test_ok --> C
      B -- test_fail --> D
    "
    # This might be tricky as conditional edges in AgentDAG require a function.
    # Maybe we map 'test_ok' to a provided function in a registry.
})

# <!-- APAF Bioinformatics | test-mermaid_parser.R | Approved | 2026-03-29 -->

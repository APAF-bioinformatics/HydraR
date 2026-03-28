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
    parsed <- parse_mermaid(mermaid)
    
    expect_equal(nrow(parsed$nodes), 4)
    expect_equal(nrow(parsed$edges), 3)
    
    # Check labels
    expect_equal(subset(parsed$nodes, id == "A")$label, "Node A")
    expect_equal(subset(parsed$nodes, id == "B")$label, "Node B")
    expect_equal(subset(parsed$nodes, id == "C")$label, "Node C")
    expect_equal(subset(parsed$nodes, id == "D")$label, "D")
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

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-coverage_tools.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for LLM Tools and code extraction coverage
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("extract_r_code_advanced handles multiple blocks and empty input", {
  text <- "Snippet:
    ```r
    A <- 1
    ```
    More text...
    ```r
    B <- 2
    ```
  "
  res <- extract_r_code_advanced(text)
  expect_true(grepl("A <- 1", res))
  expect_true(grepl("B <- 2", res))

  expect_equal(extract_r_code_advanced(NULL), "")
  # 3. No blocks and no heuristics found -> falls back to trimmed raw text
  expect_equal(extract_r_code_advanced("no code"), "no code")
})

test_that("format_toolset handles AgentTool objects", {
  t1 <- AgentTool$new(name = "read_file", description = "reads file", parameters = list(path = "string"))
  tools <- list(t1)
  res <- format_toolset(tools)
  expect_true(is.character(res))
  expect_true(grepl("read_file", res))
})

test_that("Gemini CLI driver response extraction works", {
  # Mock a typical markdown response
  raw <- "Sure, here's some code:\n```r\nprint('hello')\n```"
  # This is usually done inside the driver$call, but we test the helper here
  expect_true(grepl("print\\('hello'\\)", extract_r_code_advanced(raw)))
})

# <!-- APAF Bioinformatics | test-coverage_tools.R | Approved | 2026-03-31 -->

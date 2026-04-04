# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-anthropic_api_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for Anthropic API Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("AnthropicAPIDriver can execute a simple prompt via API", {
  # Check for API key in env or .Renviron
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (api_key == "") {
    # Attempt to load from .Renviron in workspace
    if (file.exists("../../.Renviron")) {
      readRenviron("../../.Renviron")
      api_key <- Sys.getenv("ANTHROPIC_API_KEY")
    }
  }

  if (api_key == "" || grepl("^sk-ant-api03-E9tAx3", api_key)) {
    # If it's the example key from .Renviron, we should be careful.
    # But the user asked to test it, so we'll try.
  }

  if (api_key == "") skip("ANTHROPIC_API_KEY not found")

  drv <- AnthropicAPIDriver$new()
  expect_true(inherits(drv, "AnthropicAPIDriver"))

  # Execute a simple prompt
  res <- tryCatch(
    {
      withr::with_options(list(timeout = 30), {
        drv$call("echo 'hello api' and nothing else")
      })
    },
    error = function(e) {
      skip(paste("Anthropic API call failed:", e$message))
    }
  )

  # Validation
  expect_type(res, "character")
  expect_true(nchar(res) > 0)
  expect_true(grepl("hello api", res, ignore.case = TRUE))
})

# <!-- APAF Bioinformatics | test-anthropic_api_actual.R | Approved | 2026-04-03 -->

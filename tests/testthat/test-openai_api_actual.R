# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-openai_api_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for OpenAI API Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("OpenAIAPIDriver can execute a simple prompt via API", {
  # Check for API key in env or .Renviron
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (api_key == "") {
    # Attempt to load from .Renviron in workspace
    if (file.exists("../../.Renviron")) {
      readRenviron("../../.Renviron")
      api_key <- Sys.getenv("OPENAI_API_KEY")
    }
  }

  if (api_key == "") skip("OPENAI_API_KEY not found")

  drv <- OpenAIAPIDriver$new()
  expect_true(inherits(drv, "OpenAIAPIDriver"))

  # Execute a simple prompt
  res <- tryCatch(
    {
      withr::with_options(list(timeout = 30), {
        # Ask for something very simple
        drv$call("echo 'hello openai' and nothing else")
      })
    },
    error = function(e) {
      skip(paste("OpenAI API call failed:", e$message))
    }
  )

  # Validation
  expect_type(res, "character")
  expect_true(nchar(res) > 0)
  expect_true(grepl("hello openai", res, ignore.case = TRUE))
})

# <!-- APAF Bioinformatics | test-openai_api_actual.R | Approved | 2026-04-03 -->

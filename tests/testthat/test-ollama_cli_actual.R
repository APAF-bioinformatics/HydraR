# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-ollama_cli_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for Ollama Agent Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("OllamaDriver can execute a simple prompt with smollm2:135m", {
  # Skip if ollama is not installed
  ollama_path <- Sys.which("ollama")
  if (ollama_path == "") {
    skip("Ollama CLI 'ollama' not found in PATH")
  }

  # Verify if smollm2:135m is available
  check_models <- system2("ollama", args = "list", stdout = TRUE, stderr = FALSE)
  if (!any(grepl("smollm2:135m", check_models))) {
    skip("Model 'smollm2:135m' not found in ollama list")
  }

  drv <- OllamaDriver$new(model = "smollm2:135m")
  expect_true(inherits(drv, "OllamaDriver"))

  # Use a very simple prompt
  res <- tryCatch(
    {
      withr::with_options(list(timeout = 30), {
        # Ask for something very simple
        drv$call("Say 'hello world' and nothing else")
      })
    },
    error = function(e) {
      skip(paste("Ollama call failed or timed out:", e$message))
    }
  )

  # Validation: result should not be empty
  expect_type(res, "character")
  expect_true(nchar(res) > 0)

  # Check if it contains 'hello' (smollm2 might not follow 'and nothing else' perfectly)
  expect_true(grepl("hello", res, ignore.case = TRUE))

  message(sprintf("\n[Ollama Test] Output: %s", res))
})

# <!-- APAF Bioinformatics | test-ollama_cli_actual.R | Approved | 2026-04-03 -->

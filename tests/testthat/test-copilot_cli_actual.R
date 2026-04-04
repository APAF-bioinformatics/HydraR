# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-copilot_cli_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for Copilot CLI Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("CopilotCLIDriver can execute a simple prompt", {
  # Skip if gh is not installed
  gh_path <- Sys.which("gh")
  if (gh_path == "") {
    skip("GitHub CLI 'gh' not found in PATH")
  }

  # Check if gh copilot extension is available by trying to get help
  # This avoids hanging if the user hasn't authorized it yet
  check_cmd <- try(system2("gh", args = c("copilot", "--", "--help"), stdout = NULL, stderr = NULL), silent = TRUE)
  if (inherits(check_cmd, "try-error") || check_cmd != 0) {
    skip("GitHub Copilot CLI extension not functional or not authorized")
  }

  drv <- CopilotCLIDriver$new()
  expect_true(inherits(drv, "CopilotCLIDriver"))

  # Use a very simple prompt that should return a predictable shell command
  # We use a timeout to prevent hanging the test suite
  res <- tryCatch(
    {
      withr::with_options(list(timeout = 10), {
        drv$call("echo hello world")
      })
    },
    error = function(e) {
      skip(paste("Copilot CLI call failed or timed out:", e$message))
    }
  )

  # Validation: result should not be empty
  expect_type(res, "character")
  # Depending on the model response, it might be exactly "echo hello world" or similar
  expect_true(nchar(res) > 0)
})

# <!-- APAF Bioinformatics | test-copilot_cli_actual.R | Approved | 2026-04-03 -->

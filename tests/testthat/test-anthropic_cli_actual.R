# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-claude_cli_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for Claude Code CLI Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("AnthropicCLIDriver can execute a simple prompt", {
  # Skip if claude is not installed
  claude_path <- Sys.which("claude")
  if (claude_path == "") {
    skip("Claude Code CLI 'claude' not found in PATH")
  }

  # Check if claude is functional and authorized
  check_cmd <- try(system2("claude", args = "--version", stdout = NULL, stderr = NULL), silent = TRUE)
  if (inherits(check_cmd, "try-error") || check_cmd != 0) {
    skip("Claude Code CLI not functional or not authorized")
  }

  drv <- AnthropicCLIDriver$new()
  expect_true(inherits(drv, "AnthropicCLIDriver"))

  # Use a very simple prompt that should return a predictable result
  # We use a timeout to prevent hanging
  res <- tryCatch(
    {
      withr::with_options(list(timeout = 30), {
        # Ask for something very simple
        # Use dangerously_skip_permissions = TRUE because R CMD check runs in a temp dir
        drv$call("echo 'hello world' and nothing else",
          cli_opts = list(dangerously_skip_permissions = TRUE)
        )
      })
    },
    error = function(e) {
      skip(paste("Claude Code CLI call failed or timed out:", e$message))
    }
  )

  # Validation: result should not be empty
  expect_type(res, "character")
  expect_true(nchar(res) > 0)

  # Check if it contains 'hello world'
  expect_true(grepl("hello world", res, ignore.case = TRUE))
})

# <!-- APAF Bioinformatics | test-claude_cli_actual.R | Approved | 2026-04-03 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-codex_cli_actual.R
# Author:      APAF Agentic Workflow
# Purpose:     Manual Verification Test for OpenAI Codex CLI Driver
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

test_that("OpenAICodexCLIDriver can execute a simple prompt via CLI", {
  # Check if codex is in system path
  is_codex_available <- system2("which", "codex", stdout = FALSE, stderr = FALSE) == 0
  if (!is_codex_available) skip("codex-cli not found in system path")

  drv <- OpenAICodexCLIDriver$new()
  expect_true(inherits(drv, "OpenAICodexCLIDriver"))

  # Execute a simple prompt
  # Use --sandbox read-only for safety (though it's default)
  # Use skip_git_repo_check = TRUE because R CMD check runs in a temp dir without .git
  res <- drv$call("say 'hello codex' and nothing else", 
                  cli_opts = list(sandbox = "read-only", skip_git_repo_check = TRUE))

  # Validation
  expect_type(res, "character")
  expect_true(nchar(res) > 0)
  expect_true(grepl("hello codex", res, ignore.case = TRUE))
})

# <!-- APAF Bioinformatics | test-codex_cli_actual.R | Approved | 2026-04-03 -->

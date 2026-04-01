library(testthat)
library(HydraR)

test_that("cleanup_jules_branches handles dry run securely", {
  # Skip if not in a git repo (e.g. during devtools::check())
  repo <- getwd()
  is_git <- system2("git", c("-C", shQuote(repo), "rev-parse", "--is-inside-work-tree"), stdout = FALSE, stderr = FALSE) == 0
  skip_if_not(is_git, "Not in a git repository")

  # Ensure it doesn't crash and identifies main as protected
  # Since I already cleaned up, it should return 0 branches
  res <- cleanup_jules_branches(repo_root = repo, dry_run = TRUE, verbose = FALSE)

  expect_type(res, "character")
  # Protected branches should NEVER be in the list
  expect_false("main" %in% res)
  expect_false("gh-pages" %in% res)
  expect_false("HEAD" %in% res)
})

test_that("cleanup_jules_branches fails gracefully on non-git repos", {
  tmp_dir <- withr::local_tempdir()
  # Should either throw an error or return character(0)
  # But system2("git", ...) will usually return exit code 128
  # My function currently assumes it's a git repo.

  # Let's ensure it doesn't crash the whole session
  expect_error(cleanup_jules_branches(repo_root = tmp_dir, verbose = FALSE))
})

# <!-- APAF Bioinformatics | test-git_cleanup.R | Approved | 2026-04-01 -->

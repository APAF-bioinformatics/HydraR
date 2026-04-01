library(testthat)
library(HydraR)

test_that("cleanup_jules_branches handles dry run securely", {
  # Initialize a temporary git repo to ensure the test has a valid git env
  repo <- withr::local_tempdir()
  remote_repo <- withr::local_tempdir()

  # Create a dummy remote repo
  system2("git", c("-C", shQuote(remote_repo), "init", "--bare"), stdout = FALSE, stderr = FALSE)

  # Create local repo
  system2("git", c("-C", shQuote(repo), "init"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", shQuote(repo), "config", "user.name", "'Test User'"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", shQuote(repo), "config", "user.email", "'test@example.com'"), stdout = FALSE, stderr = FALSE)

  # Add remote to allow fetch to succeed
  system2("git", c("-C", shQuote(repo), "remote", "add", "origin", shQuote(remote_repo)), stdout = FALSE, stderr = FALSE)

  # Create an initial commit to avoid "unknown revision" errors
  writeLines("test", file.path(repo, "README.md"))
  system2("git", c("-C", shQuote(repo), "add", "README.md"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", shQuote(repo), "commit", "-m", "'Initial commit'"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", shQuote(repo), "branch", "-M", "main"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", shQuote(repo), "push", "-u", "origin", "main"), stdout = FALSE, stderr = FALSE)

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

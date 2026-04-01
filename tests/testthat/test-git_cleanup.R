library(testthat)
library(HydraR)

test_that("cleanup_jules_branches handles dry run securely", {
  # Skip if not in a git repo (e.g. during devtools::check())
  repo <- getwd()
  is_git <- system2("git", c("-C", repo, "rev-parse", "--is-inside-work-tree"), stdout = FALSE, stderr = FALSE) == 0
  skip_if_not(is_git, "Not in a git repository")

  # Mock git fetch to always succeed in test context if needed, but since we skip if no remotes,
  # it should ideally not fail on fetch if remotes exist. However, if the remote exists but is unreachable
  # we should catch that. Instead of doing network operations, let's mock system2 entirely or skip.
  # A safer approach for testing a cleanup script that modifies git state is to use a local temp dir with a dummy remote.

  tmp_dir <- withr::local_tempdir()
  system2("git", c("-C", tmp_dir, "init"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "branch", "-M", "main"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "config", "user.name", "Test User"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "config", "user.email", "test@example.com"), stdout = FALSE, stderr = FALSE)
  writeLines("test", file.path(tmp_dir, "test.txt"))
  system2("git", c("-C", tmp_dir, "add", "test.txt"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "commit", "-m", "Initial"), stdout = FALSE, stderr = FALSE)

  # Create a dummy remote
  remote_dir <- withr::local_tempdir()
  system2("git", c("-C", remote_dir, "init", "--bare"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", remote_dir, "branch", "-M", "main"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "remote", "add", "origin", remote_dir), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "push", "-u", "origin", "main"), stdout = FALSE, stderr = FALSE)

  # Create a stale branch authored by the bot
  system2("git", c("-C", tmp_dir, "checkout", "-b", "stale-branch"), stdout = FALSE, stderr = FALSE)
  writeLines("stale", file.path(tmp_dir, "stale.txt"))
  system2("git", c("-C", tmp_dir, "add", "stale.txt"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "config", "user.email", "161369871+google-labs-jules[bot]@users.noreply.github.com"), stdout = FALSE, stderr = FALSE)
  # Create a commit 48 hours ago
  system2("git", c("-C", tmp_dir, "commit", "--date=2 days ago", "-m", "Stale commit"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", tmp_dir, "push", "-u", "origin", "stale-branch"), stdout = FALSE, stderr = FALSE)

  repo <- tmp_dir

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

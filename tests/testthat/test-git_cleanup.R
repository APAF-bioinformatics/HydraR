library(testthat)
library(HydraR)

test_that("cleanup_jules_branches handles dry run securely", {
  # We should use a dedicated temporary git repo for tests
  # that run git commands. This prevents failures in CI environments
  # (e.g. `devtools::check()`) where the package source is extracted
  # from a tarball without a `.git` folder, and `getwd()` points
  # to the temporary check directory.
  tmp_dir <- withr::local_tempdir()

  withr::with_dir(tmp_dir, {
    system2("git", c("init", "-b", "main"), stdout = FALSE, stderr = FALSE)
    system2("git", c("config", "user.name", "'Test User'"), stdout = FALSE, stderr = FALSE)
    system2("git", c("config", "user.email", "'test@example.com'"), stdout = FALSE, stderr = FALSE)

    # Create an initial commit
    file.create("README.md")
    system2("git", c("add", "README.md"), stdout = FALSE, stderr = FALSE)
    system2("git", c("commit", "-m", "'Initial commit'"), stdout = FALSE, stderr = FALSE)

    # Note: cleanup_jules_branches explicitly checks remote tracking branches ("origin/*"),
    # so we need to set up a dummy remote to simulate a full checkout environment,
    # or test the function against local branches if it supports it.
    # However, since `cleanup_jules_branches` hardcodes "origin/", let's mock the remote.
    system2("git", c("remote", "add", "origin", "."), stdout = FALSE, stderr = FALSE)
    system2("git", c("fetch", "origin"), stdout = FALSE, stderr = FALSE)

    # Let's ensure it doesn't crash and identifies main as protected
    res <- cleanup_jules_branches(repo_root = tmp_dir, dry_run = TRUE, verbose = FALSE)

    expect_type(res, "character")
    expect_false("main" %in% res)
    expect_false("gh-pages" %in% res)
    expect_false("HEAD" %in% res)
  })
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

library(testthat)
library(HydraR)
library(withr)

test_that("Worktree cleanup handles busy directory gracefully", {
  # Using skip_on_os("windows") because of complex git quoting/setup below
  # Also memory instructions say: "When initializing temporary git repositories in tests via system() or system2(), explicitly configure user.name and user.email to prevent CI failures, and run git branch -M main after the initial commit"
  testthat::skip_on_os("windows")

  # 1. Setup Mock Repo
  tmp_repo <- withr::local_tempdir()
  withr::with_dir(tmp_repo, {
    system2("git", c("init"))
    system2("git", c("config", "user.name", "'Test User'"))
    system2("git", c("config", "user.email", "'test@example.com'"))
    writeLines("Initial content", "README.md")
    system2("git", c("add", "README.md"))
    system2("git", c("commit", "-m", "'Initial commit'"))
    system2("git", c("branch", "-M", "main"))
  })

  manager <- WorktreeManager$new(repo_root = tmp_repo)
  wt_path <- manager$create(node_id = "test_node_busy")

  # 2. Simulate busy directory using with_dir
  withr::with_dir(wt_path, {
    # Attempt cleanup while "inside" the worktree
    # git worktree remove typically fails if the worktree is the CWD, simulating a lock
    expect_error(manager$cleanup(), NA) # Should not throw error
  })

  # Verify it marked it as cleaned up in memory
  expect_null(manager$get_path("test_node_busy"))
})

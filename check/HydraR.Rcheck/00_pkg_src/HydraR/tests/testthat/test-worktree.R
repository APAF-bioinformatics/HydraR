library(testthat)
library(HydraR)
library(withr)

test_that("Git Worktree branch validation prevents command injection", {
  tmp_repo <- withr::local_tempdir()
  withr::with_dir(tmp_repo, {
    system2("git", c("init"))
    system2("git", c("config", "user.name", "\"APAF tester\""))
    system2("git", c("config", "user.email", "\"apaf@example.com\""))
    system2("git", c("config", "commit.gpgsign", "false"))
    writeLines("Initial content", "README.md")
    system2("git", c("add", "README.md"))
    system2("git", c("commit", "-m", "\"Initial commit\""))
    system2("git", c("branch", "-M", "main"))
  })

  manager <- WorktreeManager$new(repo_root = tmp_repo)

  # Check that hyphens at the beginning are rejected
  expect_error(
    manager$create(node_id = "node_1", branch_name = "-malicious-flag"),
    "Cannot start with a hyphen"
  )

  # Check that illegal characters are rejected
  expect_error(
    manager$create(node_id = "node_1", branch_name = "malicious;rm -rf /"),
    "Contains illegal characters"
  )

  expect_error(
    manager$create(node_id = "node_1", branch_name = "branch_with_space "),
    "Contains illegal characters"
  )

  # Valid branch should succeed
  wt_path <- manager$create(node_id = "node_1", branch_name = "valid-branch_name/123", fail_if_dirty = FALSE)
  expect_true(dir.exists(wt_path))

  # Dots in branch names should be valid
  wt_path2 <- manager$create(node_id = "node_2", branch_name = "release/1.0.0", fail_if_dirty = FALSE)
  expect_true(dir.exists(wt_path2))

  # Test remove validates
  manager$worktrees[["malicious_node"]] <- list(path = "-rf /", branch = "-rf /")
  expect_error(
    manager$remove_worktree("malicious_node"),
    "Cannot start with a hyphen"
  )
})

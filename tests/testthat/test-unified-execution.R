library(testthat)
library(HydraR)
library(withr)
library(future)
library(digest)

test_that("Unified Execution: run() defaults to .run_iterative when use_worktrees=TRUE", {
  # 1. Setup Mock Repo
  tmp_repo <- withr::local_tempdir()
  withr::with_dir(tmp_repo, {
    system2("git", c("init", "--initial-branch=main"))
    suppressWarnings(system2("git", c("checkout", "-b", "main"), stdout = FALSE, stderr = FALSE)) # ensure the branch is main on older git
    writeLines("Initial content", "README.md")
    system2("git", c("add", "README.md"))
    system2("git", c("commit", "-m", "'Initial commit'"))
  })

  # 2. Define a simple linear DAG (A -> B)
  # In linear execution without worktrees, this would normally use .run_linear.
  # We want to verify that use_worktrees=TRUE forces it into .run_iterative with isolation.

  node_a <- AgentLogicNode$new(id = "node_A", logic_fn = function(state) {
    cwd <- getwd()
    is_worktree <- grepl(".hydra_worktrees", cwd)
    list(status = "success", output = list(is_worktree = is_worktree, path = cwd))
  })

  node_b <- AgentLogicNode$new(id = "node_B", logic_fn = function(state) {
    cwd <- getwd()
    is_worktree <- grepl(".hydra_worktrees", cwd)
    list(status = "success", output = list(is_worktree = is_worktree, path = cwd))
  })

  dag <- AgentDAG$new()
  dag$add_node(node_a)
  dag$add_node(node_b)
  dag$add_edge("node_A", "node_B")

  future::plan(future::sequential)

  # Run WITH worktrees
  results <- dag$run(use_worktrees = TRUE, repo_root = tmp_repo, initial_state = list(), fail_if_dirty = FALSE)

  expect_equal(results$status, "completed")

  # Check if node_A ran in a worktree
  expect_true(results$results$node_A$output$is_worktree)
  expect_match(results$results$node_A$output$path, ".hydra_worktrees")

  # Check if node_B ran in a worktree
  expect_true(results$results$node_B$output$is_worktree)
  expect_match(results$results$node_B$output$path, ".hydra_worktrees")

  # Check trace log to verify "parallel" mode (which indicates it went through the worktree path)
  expect_equal(dag$trace_log[[1]]$mode, "parallel")
  expect_equal(dag$trace_log[[2]]$mode, "parallel")
})

test_that("Unified Execution: Linear DAG uses .run_linear when use_worktrees=FALSE", {
  dag <- AgentDAG$new()
  node_a <- AgentLogicNode$new(id = "node_A", logic_fn = function(state) {
    list(status = "success", output = "A")
  })
  dag$add_node(node_a)

  # Should use .run_linear
  results <- dag$run(use_worktrees = FALSE, initial_state = list())

  expect_equal(dag$trace_log[[1]]$mode, "linear")
})

# <!-- APAF Bioinformatics | test-unified-execution.R | Approved | 2026-03-29 -->

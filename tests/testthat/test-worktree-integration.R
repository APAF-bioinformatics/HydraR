library(testthat)
library(HydraR)
library(withr)
library(future)

test_that("Git Worktree Parallel Integration works", {
  # skip_if_no_git() - assuming git is available in this environment

  # 1. Setup Mock Repo
  tmp_repo <- withr::local_tempdir()
  withr::with_dir(tmp_repo, {
    system2("git", c("init", "--initial-branch=main"))
    suppressWarnings(system2("git", c("checkout", "-b", "main"), stdout = FALSE, stderr = FALSE))
    writeLines("Initial content", "README.md")
    system2("git", c("add", "README.md"))
    system2("git", c("commit", "-m", "'Initial commit'"))
  })

  # 2. Define Parallel Nodes
  # Simulate file modifications in different worktrees
  node_a <- AgentLogicNode$new(id = "node_A", logic_fn = function(state) {
    # Check that we are indeed in a worktree
    cwd <- getwd()
    if (!grepl(".hydra_worktrees", cwd)) {
      stop("Not in a worktree!")
    }

    writeLines("Node A content", "file_a.txt")
    system2("git", c("add", "file_a.txt"))
    system2("git", c("commit", "-m", "'Node A commit'"))
    list(status = "success", output = "Node A done")
  })

  node_b <- AgentLogicNode$new(id = "node_B", logic_fn = function(state) {
    cwd <- getwd()
    if (!grepl(".hydra_worktrees", cwd)) {
      stop("Not in a worktree!")
    }

    writeLines("Node B content", "file_b.txt")
    system2("git", c("add", "file_b.txt"))
    system2("git", c("commit", "-m", "'Node B commit'"))
    list(status = "success", output = "Node B done")
  })

  # 3. Create DAG
  dag <- AgentDAG$new()
  dag$add_node(node_a)
  dag$add_node(node_b)

  # Add Merge Harmonizer
  harmonizer <- create_merge_harmonizer(id = "merge")
  dag$add_node(harmonizer)

  dag$add_edge("node_A", "merge")
  dag$add_edge("node_B", "merge")

  # 4. Run Parallel DAG
  # IMPORTANT: We use sequential plan here so that the pause status 
  # from the MergeHarmonizer is correctly captured by the AgentDAG runner.
  future::plan(future::sequential)
  results <- dag$run(use_worktrees = TRUE, repo_root = tmp_repo, initial_state = list(), fail_if_dirty = FALSE)

  # 5. Verify Results
  expect_equal(results$status, "completed")

  # Verify files merged into main repo
  expect_true(file.exists(file.path(tmp_repo, "file_a.txt")))
  expect_true(file.exists(file.path(tmp_repo, "file_b.txt")))

  # Verify git history
  withr::with_dir(tmp_repo, {
    log <- system2("git", c("log", "--oneline"), stdout = TRUE)
    expect_true(any(grepl("Node A commit", log)))
    expect_true(any(grepl("Node B commit", log)))
  })

  # Verify cleanup (individual worktrees removed but base dir might remain)
  expect_true(dir.exists(file.path(tmp_repo, ".hydra_worktrees")))
})

test_that("Merge Conflict detection works", {
  tmp_repo <- withr::local_tempdir()
  withr::with_dir(tmp_repo, {
    system2("git", c("init", "--initial-branch=main"))
    suppressWarnings(system2("git", c("checkout", "-b", "main"), stdout = FALSE, stderr = FALSE))
    writeLines("Initial", "conflict.txt")
    system2("git", c("add", "conflict.txt"))
    system2("git", c("commit", "-m", "'Initial'"))
  })

  # Both nodes modify the same file
  node_a <- AgentLogicNode$new(id = "node_A", logic_fn = function(state) {
    writeLines("Node A edit", "conflict.txt")
    system2("git", c("add", "conflict.txt"))
    system2("git", c("commit", "-m", "'Conflicting commit A'"))
    list(status = "success", output = "A")
  })

  node_b <- AgentLogicNode$new(id = "node_B", logic_fn = function(state) {
    writeLines("Node B edit", "conflict.txt")
    system2("git", c("add", "conflict.txt"))
    system2("git", c("commit", "-m", "'Conflicting commit B'"))
    list(status = "success", output = "B")
  })

  dag <- AgentDAG$new()
  dag$add_node(node_a)
  dag$add_node(node_b)
  dag$add_node(create_merge_harmonizer(id = "merge"))
  dag$add_edge("node_A", "merge")
  dag$add_edge("node_B", "merge")

  future::plan(future::sequential)
  results <- dag$run(use_worktrees = TRUE, repo_root = tmp_repo, initial_state = list(), fail_if_dirty = FALSE)

  # Should be paused due to conflict
  expect_equal(results$status, "paused")
  expect_equal(results$paused_at, "merge")
})

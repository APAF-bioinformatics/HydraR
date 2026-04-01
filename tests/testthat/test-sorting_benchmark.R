# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-sorting_benchmark.R
# Author:      APAF Agentic Workflow
# Purpose:     Integration Test for Sorting Benchmark Workflow
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)
library(withr)
library(ggplot2)
library(future)

# 1. Setup Mock Driver that can simulate markdown fences
MockMarkdownDriver <- R6::R6Class("MockMarkdownDriver",
  inherit = AgentDriver,
  public = list(
    response = "Mocked Response",
    wrap_in_markdown = FALSE,
    initialize = function(id = "mock_markdown", response = "Mocked Response", wrap_in_markdown = FALSE) {
      super$initialize(id)
      self$response <- response
      self$wrap_in_markdown <- wrap_in_markdown
    },
    call = function(prompt, ...) {
      res <- self$response
      if (self$wrap_in_markdown) {
        res <- paste0("```r\n", res, "\n```")
      }
      return(res)
    }
  )
)

test_that("Parallel Sorting Benchmark workflow executes successfully", {
  # Setup parallel execution for test
  old_plan <- plan(multisession, workers = 2)
  on.exit(plan(old_plan), add = TRUE)
  options(future.rng.onMisuse = "ignore")

  # Setup temporary git repo
  repo_root <- file.path(tempdir(), "test_sorting_repo")
  if (dir.exists(repo_root)) unlink(repo_root, recursive = TRUE)
  dir.create(repo_root)
  on.exit(unlink(repo_root, recursive = TRUE), add = TRUE)

  withr::with_dir(repo_root, {
    system("git init", ignore.stdout = TRUE)
    system("git config user.email 'apaf@example.com'")
    system("git config user.name 'APAF tester'")
    system("git config commit.gpgsign false")
    writeLines("# Sorting Test", "README.md")
    system("git add README.md")
    system("git commit -m 'Initial commit'", ignore.stdout = TRUE)
    system("git branch -M main", ignore.stdout = TRUE)
  })

  # Node Factory
  sorting_node_factory <- function(id, label, params) {
    if (id == "merger") {
      return(create_merge_harmonizer(id = id))
    }

    if (id == "benchmark") {
      return(AgentLogicNode$new(id, function(state) {
        # Ensure worktree is synced with the merged main branch
        system("git checkout main", ignore.stdout = TRUE, ignore.stderr = TRUE)

        # Source all generated files
        files <- list.files(pattern = "_sort.R")
        purrr::walk(files, source)

        n_elements <- 10
        methods <- c("bubble", "quick", "merge")
        results_df <- purrr::map_df(methods, function(m) {
          func_name <- paste0(m, "_sort")
          if (!exists(func_name)) {
            return(NULL)
          }
          func <- get(func_name)
          times <- replicate(2, {
            test_data <- rnorm(n_elements)
            start <- Sys.time()
            func(test_data)
            as.numeric(difftime(Sys.time(), start, units = "secs"))
          })
          data.frame(method = m, time = times)
        })
        list(status = "success", output = results_df)
      }))
    }

    if (id == "plot") {
      return(AgentLogicNode$new(id, function(state) {
        df <- state$get("benchmark")
        if (is.null(df) || nrow(df) == 0) {
          return(list(status = "failed", error = "No data"))
        }

        p <- ggplot(df, aes(x = method, y = time, fill = method)) +
          geom_boxplot()

        # Save plot to the repo_root for access
        plot_path <- file.path(state$get("repo_root"), "test_sorting_benchmark.pdf")
        ggsave(plot_path, p, width = 8, height = 6)

        list(status = "success", output = "Plot rendered.")
      }))
    }

    # Algorithm generation nodes
    algo_code <- switch(id,
      bubble = "bubble_sort <- function(x) { x[order(x)] }",
      quick = "quick_sort <- function(x) { sort(x) }",
      merge = "merge_sort <- function(x) { sort(x, method = 'radix') }"
    )

    # Use markdown wrapper for 'bubble' to test extract_r_code_advanced
    driver <- MockMarkdownDriver$new(response = algo_code, wrap_in_markdown = (id == "bubble"))

    # USE THE HARDENED AgentLLMNode
    AgentLLMNode$new(id,
      role = "Expert",
      driver = driver,
      label = label,
      params = list(
        output_format = "r",
        output_path = paste0(id, "_sort.R")
      )
    )
  }

  mermaid_graph <- '
  graph TD
      bubble["Bubble Agent"] --> merger
      quick["Quick Agent"] --> merger
      merge["Merge Agent"] --> merger
      merger["Merge Harmonizer"] --> benchmark
      benchmark["Benchmark Performance"] --> plot
      plot["Visualize Results"]
  '

  dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = sorting_node_factory)
  compiled_dag <- dag$compile()

  # Run the DAG
  results <- compiled_dag$run(
    initial_state = list(repo_root = repo_root),
    use_worktrees = TRUE,
    repo_root = repo_root,
    fail_if_dirty = FALSE,
    packages = c("HydraR", "ggplot2", "withr")
  )

  # Assertions
  # Assert result structure matches AgentDAG return
  expect_equal(results$status, "completed")
  expect_true("plot" %in% names(results$results))
  expect_equal(compiled_dag$trace_log[[length(compiled_dag$trace_log)]]$status, "success")

  # Check if files were merged
  withr::with_dir(repo_root, {
    merged_files <- list.files(pattern = "_sort.R")
    expect_true("bubble_sort.R" %in% merged_files)
    expect_true("quick_sort.R" %in% merged_files)
    expect_true("merge_sort.R" %in% merged_files)
  })

  # Save Trace and Copy PDF to project root for user access
  # Use ../.. if running inside tests/testthat, else current dir
  proj_root <- if (dir.exists("../..") && dir.exists("../../tests")) "../.." else "."

  compiled_dag$save_trace(file.path(proj_root, "sorting_trace.json"))
  file.copy(file.path(repo_root, "test_sorting_benchmark.pdf"), file.path(proj_root, "sorting_benchmark.pdf"), overwrite = TRUE)
})

# <!-- APAF Bioinformatics | test-sorting_benchmark.R | Approved | 2026-03-30 -->

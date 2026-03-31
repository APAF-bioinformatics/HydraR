## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup, eval = FALSE------------------------------------------------------
# library(HydraR)
# library(withr)
# library(ggplot2)
# 
# # Ensure Gemini CLI path is configured (Environment variables are inherited by workers)
# Sys.setenv(HYDRAR_GEMINI_PATH = "/opt/homebrew/bin/gemini")
# 
# # Define the repository root for worktrees
# repo_root <- "."
# 
# # 0. Setup Parallel Execution (for Worktree Isolation)
# plan(multisession, workers = 3, envir = globalenv())
# options(future.rng.onMisuse = "ignore")
# 
# # 1. Create a temporary folder
# repo_root <- file.path(tempdir(), "sorting-benchmark-repo")
# if (dir.exists(repo_root)) unlink(repo_root, recursive = TRUE)
# dir.create(repo_root)
# 
# # 2. Initialize Git and a README
# withr::with_dir(repo_root, {
#   system("git init -b main")
#   system("git config user.email 'apaf@example.com'")
#   system("git config user.name 'APAF Agent'")
#   system("git config commit.gpgsign false")
#   writeLines("# Sorting Benchmark", "README.md")
#   system("git add README.md")
#   system("git commit -m 'Initial commit'")
# })

## ----load_wf, eval = FALSE----------------------------------------------------
# # 1. Load the workflow manifest
# wf <- load_workflow("vignettes/sorting_benchmark.yml")
# 
# # 2. Extract components
# mermaid_graph <- wf$graph
# initial_state <- wf$initial_state
# 
# # 3. Inject dynamic environment variables into initial state
# initial_state$repo_root <- repo_root
# 
# # 4. Instantiate and Compile
# dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = auto_node_factory())
# compiled_dag <- dag$compile()
# 
# # 5. Run with Worktree Isolation
# # Ensure workers inherit our environment (for API keys and PATH)
# future::plan(future::multisession, workers = 3, envir = globalenv())
# 
# results <- compiled_dag$run(
#   initial_state = initial_state,
#   use_worktrees = TRUE,
#   repo_root = repo_root,
#   fail_if_dirty = FALSE,
#   packages = c("withr", "HydraR", "ggplot2")
# )
# 
# # 6. Save Execution Trace
# compiled_dag$save_trace("sorting_trace.json")


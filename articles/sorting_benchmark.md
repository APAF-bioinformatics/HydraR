# Parallel Benchmarking with Git Worktrees

## Overview

Modern agentic workflows often involve multiple specialized agents
working on different parts of a codebase simultaneously. When these
agents modify files, they risk stepping on each other’s toes—causing
merge conflicts or corrupted git states.

`HydraR` addresses this by leveraging **Git Worktrees** for isolated
execution. This guide demonstrates a parallel workflow where: 1. **Three
Agents** simultaneously write R code for different sorting algorithms
(Bubble, Quick, Merge sort) in separate worktrees. 2. A **Merge
Harmonizer** automatically merges these independent branches back into
the main repository. 3. A **Benchmarking Node** executes the generated
code to compare their performance. 4. A **Visualization Node** plots the
results.

------------------------------------------------------------------------

## 🏗️ Step 1: Initialize an Isolated Repository

To demonstrate the power of worktrees, we first create a temporary Git
repository.

``` r
library(HydraR)
library(withr)
library(ggplot2)
library(future)
library(furrr)

# Check for Anthropic API Key (Needed for refined agents)
# Must be done BEFORE future::plan so workers inherit the environment
if (Sys.getenv("ANTHROPIC_API_KEY") == "") {
  if (file.exists("../.Renviron")) readRenviron("../.Renviron")
  if (file.exists(".Renviron")) readRenviron(".Renviron")
}

if (Sys.getenv("ANTHROPIC_API_KEY") == "") {
  stop("ANTHROPIC_API_KEY not found. Please set it in your .Renviron or workspace.")
}

# Ensure Gemini CLI path is configured (Environment variables are inherited by workers)
Sys.setenv(HYDRAR_GEMINI_PATH = "/opt/homebrew/bin/gemini")

# 0. Setup Parallel Execution (for Worktree Isolation)
future::plan(future::multisession, workers = 3)
options(future.rng.onMisuse = "ignore")

# 1. Create a temporary folder
repo_root <- file.path(tempdir(), "sorting-benchmark-repo")
if (dir.exists(repo_root)) unlink(repo_root, recursive = TRUE)
dir.create(repo_root)

# 2. Initialize Git and a README
withr::with_dir(repo_root, {
  system2("git", c("init"))
  system2("git", c("config", "user.email", "apaf@example.com"))
  system2("git", c("config", "user.name", "APAF Agent"))
  system2("git", c("config", "commit.gpgsign", "false"))
  writeLines("# Sorting Benchmark", "README.md")
  system2("git", c("add", "README.md"))
  system2("git", c("commit", "-m", "Initial_commit"))
  system2("git", c("branch", "-M", "main"))
})
```

------------------------------------------------------------------------

## 🧠 Step 2: Declarative Workflow Loading

Rather than registering roles and logic manually in R, we now define the
entire workflow architecture (graph, prompts, logic) in a single
declarative YAML file. This follows the **APAF-Agentic-Standard** for
Zero-R-Code definitions.

``` r
# 1. Load the workflow manifest
wf <- load_workflow("sorting_benchmark.yml")

# 2. Extract components
mermaid_graph <- wf$graph
initial_state <- wf$initial_state

# 3. Inject dynamic environment variables into initial state
initial_state$repo_root <- repo_root
initial_state$output_dir <- file.path(getwd(), "..", "paper", "figures")

# 4. Instantiate and Compile
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = auto_node_factory())
compiled_dag <- dag$compile()

# 5. Run with Worktree Isolation
# Ensure workers inherit our environment (for API keys and PATH)
future::plan(future::multisession, workers = 3)

results <- compiled_dag$run(
  initial_state = initial_state,
  use_worktrees = TRUE,
  repo_root = repo_root,
  fail_if_dirty = FALSE,
  packages = c("withr", "HydraR", "ggplot2")
)

# 6. Save Execution Trace
compiled_dag$save_trace("sorting_trace.json")
```

------------------------------------------------------------------------

## 🧘 Summary

By using **Declarative Mermaid Nodes** with
[`auto_node_factory()`](https://github.com/APAF-bioinformatics/HydraR/reference/auto_node_factory.md),
we: 1. **Eliminated Boilerplate**: No hand-written node factory — the
Mermaid graph IS the specification. 2. **Eliminated State Corruption**:
Three agents modified the codebase simultaneously via isolated Git
Worktrees. 3. **Automated Conflict Resolution**: The `MergeHarmonizer`
handled integration of branches. 4. **End-to-End Validation**: Generated
code was benchmarked immediately downstream.

------------------------------------------------------------------------

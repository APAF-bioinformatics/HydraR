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

# Define the repository root for worktrees
repo_root <- "."

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

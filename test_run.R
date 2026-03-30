
# Use local package source
devtools::load_all(".")
library(future)
library(withr)
library(ggplot2)

# Ensure Gemini CLI path is configured
Sys.setenv(HYDRAR_GEMINI_PATH = "/opt/homebrew/bin/gemini")

# API Key Check
if (Sys.getenv("GEMINI_API_KEY") == "") {
  warning("GEMINI_API_KEY is not set. The Gemini CLI driver will fail.\nSet it with: Sys.setenv(GEMINI_API_KEY = 'your_key_here')")
}

# Define the repository root for worktrees
repo_root <- file.path(getwd(), "repro_repo")
if (dir.exists(repo_root)) unlink(repo_root, recursive = TRUE)
dir.create(repo_root)

# Initialize Git and a README
withr::with_dir(repo_root, {
  system("git init -b main")
  system("git config user.email 'apaf@example.com'")
  system("git config user.name 'APAF Agent'")
  system("git config commit.gpgsign false")
  writeLines("# Sorting Benchmark", "README.md")
  system("git add README.md")
  system("git commit -m 'Initial commit'")
})

# Load the workflow
wf <- load_workflow("vignettes/sorting_benchmark.yml")
mermaid_graph <- wf$graph
initial_state <- wf$initial_state
initial_state$repo_root <- repo_root

# Instantiate and Compile
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = auto_node_factory())
compiled_dag <- dag$compile()

# Run Sequential for debugging (or workers = 1)
future::plan(future::sequential)

results <- compiled_dag$run(
  initial_state = initial_state,
  use_worktrees = TRUE,
  repo_root = repo_root,
  fail_if_dirty = FALSE,
  packages = c("withr", "HydraR", "ggplot2")
)

# Save Execution Trace
compiled_dag$save_trace("repro_trace.json")

cat("\n--- Execution Summary ---\n")
print(results$status)
cat("\n--- Node Results ---\n")
purrr::iwalk(results$results, function(res, id) {
  cat(sprintf("[%s] Status: %s\n", id, res$status))
  if (res$status == "failed") {
    # Try to find the error in the trace or result
    cat(sprintf("  Error: %s\n", paste(res$error, collapse = "\n")))
    # If the node is an LLM node, the error might be more descriptive in the last_result of the node itself
    node <- compiled_dag$nodes[[id]]
    if (inherits(node, "AgentLLMNode") && !is.null(node$last_result$error)) {
       cat(sprintf("  Detailed Error: %s\n", node$last_result$error))
    }
  }
})

library(HydraR)
library(withr)
library(ggplot2)
library(future)

# Define the repository root for worktrees
repo_root <- file.path("/tmp", "sorting-benchmark-repo")
if (dir.exists(repo_root)) unlink(repo_root, recursive = TRUE)
dir.create(repo_root)

# 2. Initialize Git and a README
withr::with_dir(repo_root, {
  system("git init -b main")
  system("git config user.email 'apaf@example.com'")
  system("git config user.name 'APAF Agent'")
  system("git config commit.gpgsign false")
  writeLines("# Sorting Benchmark", "README.md")
  system("git add README.md")
  system("git commit -m 'Initial commit'")
})

# 3. Load the workflow manifest from vignettes/
wf <- load_workflow("vignettes/sorting_benchmark.yml")

# 4. Instantiate and Compile
dag <- spawn_dag(wf, auto_node_factory())

# 5. Setup Parallel Execution (for Worktree Isolation)
plan(multisession, workers = 3)

# 6. Run with Worktree Isolation
message("Starting DAG run...")
results <- dag$run(
  initial_state = append(wf$initial_state, list(repo_root = repo_root)),
  use_worktrees = TRUE,
  repo_root = repo_root,
  fail_if_dirty = FALSE,
  packages = c("withr", "HydraR", "ggplot2")
)

message("Status: ", results$status)
message("Repo Root contents: ", paste(list.files(repo_root), collapse = ", "))

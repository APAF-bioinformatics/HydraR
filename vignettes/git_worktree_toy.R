## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup, eval = FALSE------------------------------------------------------
# library(HydraR)
# library(withr)
# 
# # 1. Create a temporary folder
# repo_root <- file.path(tempdir(), "hydra-toy-repo")
# dir.create(repo_root)
# 
# # 2. Initialize Git and a README
# withr::with_dir(repo_root, {
#   system("git init -b main")
#   system("git config user.email 'apaf@example.com'")
#   system("git config user.name 'APAF Agent'")
#   writeLines("# Toy Project", "README.md")
#   system("git add README.md")
#   system("git commit -m 'Initial commit'")
# })

## ----logic_registry, eval = FALSE---------------------------------------------
# git_logic_registry <- list(
#   # 1. Agent Roles
#   roles = list(
#     code_creator = "Generate a simple R function to calculate the square of a number. SAVE IT to a file named 'math_fun.R'. Output ONLY the code."
#   ),
# 
#   # 2. Prompt Builders
#   prompts = list(
#     code_creator = function(state) {
#       # In this example, we use the role as the direct prompt for simplicity
#       git_logic_registry$roles$code_creator
#     }
#   )
# )

## ----factory, eval = FALSE----------------------------------------------------
# git_node_factory <- function(id, label, params) {
#   if (id == "merger") {
#     # Resolve the specialized MergeHarmonizer node
#     create_merge_harmonizer(id = id)
#   } else {
#     # Resolve standard LLM nodes
#     driver_obj <- if (!is.null(params[["driver"]]) && params[["driver"]] == "gemini") GeminiCLIDriver$new() else NULL
# 
#     AgentLLMNode$new(
#       id = id,
#       label = label,
#       role = git_logic_registry$roles[[id]],
#       driver = driver_obj,
#       prompt_builder = git_logic_registry$prompts[[id]]
#     )
#   }
# }

## ----mermaid_source, eval = FALSE---------------------------------------------
# mermaid_graph <- "
# graph TD
#   code_creator[Code Creator | driver=gemini] --> merger
#   merger[Merge Harmonizer]
# "
# 
# # Instantiate the DAG
# dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = git_node_factory)
# compiled_dag <- dag$compile()

## ----run_dag, eval = FALSE----------------------------------------------------
# # Run the DAG from the temporary repo root
# results <- compiled_dag$run(
#   initial_state = list(input = "Start execution"),
#   use_worktrees = TRUE,
#   repo_root = repo_root,
#   fail_if_dirty = FALSE # Allow running in the new repo
# )
# 
# # Verify the file was merged into the main repo branch
# list.files(repo_root)
# # [1] "README.md" "math_fun.R"


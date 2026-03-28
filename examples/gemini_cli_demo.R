#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        gemini_cli_demo.R
#' Purpose:     Demo HydraR with Gemini CLI Driver
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

# 1. Load HydraR (dev)
base_dir <- "/Users/ignatiuspang/Workings/2026/HydraR/R"
source(file.path(base_dir, "state.R"))
source(file.path(base_dir, "dag.R"))
source(file.path(base_dir, "node.R"))
source(file.path(base_dir, "node_llm.R"))
source(file.path(base_dir, "driver.R"))
source(file.path(base_dir, "drivers_cli.R"))
source(file.path(base_dir, "checkpointer.R"))

# 2. Setup Driver
driver <- GeminiCLIDriver$new(model = "gemini-1.5-flash")

# 3. Define LLM Node
node_agent <- AgentLLMNode$new(
    id = "writer",
    role = "You are a poetic assistant specializing in bioinformatics.",
    driver = driver,
    prompt_builder = function(state) {
        sprintf("Write a 2-line poem about: %s", state$get("topic"))
    }
)

# 4. Create DAG
dag <- AgentDAG$new()
dag$add_node(node_agent)
dag$compile()

# 5. Run
cat("\n🚀 Running Gemini CLI Agent...\n")
res <- dag$run(initial_state = list(topic = "DNA sequencing"))

cat("\n--- Result ---\n")
cat(res$results$writer$output, "\n")

# <!-- APAF Bioinformatics | gemini_cli_demo.R | Example | 2026-03-28 -->

#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        hello_world.R
#' Purpose:     Example HydraR Agentic Loop
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

# 1. Load HydraR (assuming development for now)
# library(HydraR)
# For manual sourcing (dev):
base_dir <- "/Users/ignatiuspang/Workings/2026/HydraR/R"
source(file.path(base_dir, "state.R"))
source(file.path(base_dir, "dag.R"))
source(file.path(base_dir, "node.R"))
source(file.path(base_dir, "logic_node.R"))
source(file.path(base_dir, "checkpointer.R"))

# 2. Define Logic Nodes
node_input <- AgentLogicNode$new(
    id = "collect_input",
    logic_fn = function(state) {
        list(status = "SUCCESS", output = list(input_raw = state$get("input")))
    }
)

node_process <- AgentLogicNode$new(
    id = "process_data",
    logic_fn = function(state) {
        raw <- state$get("input_raw")
        res <- paste0("HYDRAR says: ", toupper(raw))
        list(status = "SUCCESS", output = list(processed_result = res))
    }
)

# 3. Create DAG
dag <- AgentDAG$new()
dag$add_node(node_input)
dag$add_node(node_process)
dag$add_edge("collect_input", "process_data")

dag$compile()

# 4. Execute with State & Checkpointer
checkpointer <- MemorySaver$new()
thread_id <- "test_run_001"

final <- dag$run(
    initial_state = list(input = "hello hydra"),
    checkpointer = checkpointer,
    thread_id = thread_id
)

# 5. Output Verification
cat("\n--- Final Results ---\n")
print(final$results$process_data$output$processed_result)

# 6. Verify Checkpoint
cat("\n--- Verifying Checkpoint ---\n")
restored <- checkpointer$get(thread_id)
print(restored$get("processed_result"))

# <!-- APAF Bioinformatics | hello_world.R | Example | 2026-03-28 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        run_hong_kong.R
# Purpose:     Execute the Hong Kong Travel DAG from vignette
# ==============================================================

library(devtools)
load_all(".") # Load HydraR from project root

# Load the workflow from the declarative YAML
message("Loading workflow from vignettes/hong_kong_travel.yml...")
wf <- load_workflow("vignettes/hong_kong_travel.yml")

# Instantiate the DAG
message("Spawning DAG...")
dag <- spawn_dag(wf, auto_node_factory())

# Configure checkpointer
message("Initializing DuckDBSaver...")
checkpointer <- DuckDBSaver$new(db_path = "travel_booking.duckdb")

# Run Orchestration
message("Executing DAG...")
FORCE_REGENERATE_IMAGES <- TRUE
ASPECT_RATIO <- "16:9"

results <- dag$run(
  initial_state = append(wf$initial_state, list(
    force_regenerate_images = FORCE_REGENERATE_IMAGES,
    aspect_ratio = ASPECT_RATIO
  )),
  max_steps = 15,
  checkpointer = checkpointer
)

message("Execution Complete.")
saveRDS(results, "execution_results.rds")

# <!-- APAF Bioinformatics | run_hong_kong.R | Approved | 2026-04-02 -->

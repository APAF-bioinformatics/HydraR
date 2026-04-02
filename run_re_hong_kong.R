# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        run_re_hong_kong.R
# Purpose:     Re-execute the Hong Kong Travel DAG with full logging
# ==============================================================

library(usethis)
devtools::load_all(".")

# Print absolute directory path for user discovery
cat(sprintf("[%s] [System] Absolute Working Directory: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), getwd()))

# Load workflow
wf_path <- "vignettes/hong_kong_travel.yml"
cat(sprintf("[%s] [System] Loading workflow from %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), normalizePath(wf_path)))
wf <- load_workflow(wf_path)

# Spawn DAG
cat(sprintf("[%s] [System] Spawning DAG...\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
dag <- spawn_dag(wf)

# Configure Checkpointer
db_path <- "vignettes/travel_booking.duckdb"
cat(sprintf("[%s] [System] Initializing DuckDBSaver at %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), normalizePath(db_path, mustWork = FALSE)))
checkpointer <- DuckDBSaver$new(db_path = db_path)

# Execute
cat(sprintf("[%s] [System] Executing DAG...\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
results <- dag$run(
  max_steps = 15,
  checkpointer = checkpointer,
  initial_state = wf$initial_state
)

cat(sprintf("[%s] [System] Execution Complete.\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
saveRDS(results, "execution_results.rds")

# Print final artifact locations
artifacts <- c(
  "vignettes/hong_kong_itinerary.md",
  "vignettes/hong_kong_pamphlet.html",
  "vignettes/validation_report.md"
)
cat("\n=== Generated Artifacts (Absolute Paths) ===\n")
purrr::walk(artifacts, \(a) {
  if (file.exists(a)) {
    cat(sprintf("- %s\n", normalizePath(a)))
  }
})

# <!-- APAF Bioinformatics | run_re_hong_kong.R | Approved | 2026-04-03 -->

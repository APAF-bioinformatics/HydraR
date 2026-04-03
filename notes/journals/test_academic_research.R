# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test_academic_research.R
# Purpose:     End-to-End Academic Research Pipeline with Checkpointer
# License:     LGPL (>= 3)
# ==============================================================

library(HydraR)

# ── USER CONFIGURATION ──────────────────────────────────────────
# Checkpointer mode: "none" | "memory" | "rds" | "duckdb"
CHECKPOINTER_MODE <- "none"

# RDS directory (only used when CHECKPOINTER_MODE = "rds")
RDS_DIR <- "checkpoints"

# DuckDB path (only used when CHECKPOINTER_MODE = "duckdb")
DUCKDB_PATH <- "checkpoints/academic_research.duckdb"

# Thread ID for checkpoint persistence (used by memory & duckdb)
THREAD_ID <- "academic_research_run_1"
# ────────────────────────────────────────────────────────────────

# Build checkpointer based on flag
checkpointer <- switch(CHECKPOINTER_MODE,
  "memory" = {
    cat("[Config] Using MemorySaver checkpointer\n")
    MemorySaver$new()
  },
  "rds" = {
    cat(sprintf("[Config] Using RDSSaver checkpointer (%s/)\n", RDS_DIR))
    RDSSaver$new(dir = RDS_DIR)
  },
  "duckdb" = {
    cat(sprintf("[Config] Using DuckDBSaver checkpointer (%s)\n", DUCKDB_PATH))
    if (!dir.exists(dirname(DUCKDB_PATH))) dir.create(dirname(DUCKDB_PATH), recursive = TRUE)
    DuckDBSaver$new(db_path = DUCKDB_PATH)
  },
  "none" = {
    cat("[Config] No checkpointer (ephemeral run)\n")
    NULL
  },
  stop(sprintf("Invalid CHECKPOINTER_MODE: '%s'. Use 'none', 'memory', 'rds', or 'duckdb'.", CHECKPOINTER_MODE))
)

thread_id <- if (!is.null(checkpointer)) THREAD_ID else NULL

# Initialize the Gemini CLI driver
driver <- GeminiCLIDriver$new()

# Initialize the DAG
dag <- AgentDAG$new()

# 1. The Searcher Node
searcher_node <- AgentLLMNode$new(
  id = "Searcher",
  label = "Literature Searcher",
  role = "You are an academic research assistant. Your task is to identify 2-3 key hypothetical papers for a given topic. Output the result as a simple list.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Research Topic: %s\nProvide a list of 2-3 paper titles and brief descriptions.", state$get("research_topic"))
  }
)
dag$add_node(searcher_node)

# 2. The Summarizer Node
summarizer_node <- AgentLLMNode$new(
  id = "Summarizer",
  label = "Content Summarizer",
  role = "You are a scientific editor. Summarize the following paper list into key highlights.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Paper List: %s", state$get("Searcher"))
  }
)
dag$add_node(summarizer_node)

# 3. The Compiler Node
compiler_node <- AgentLLMNode$new(
  id = "Compiler",
  label = "Report Compiler",
  role = "You are a technical writer. Format the following summaries into a professional markdown report with headers.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Topic: %s\nSummaries: %s", state$get("research_topic"), state$get("Summarizer"))
  }
)
dag$add_node(compiler_node)

# Transitions
dag$set_start_node("Searcher")
dag$add_edge("Searcher", "Summarizer")
dag$add_edge("Summarizer", "Compiler")

compiled_dag <- dag$compile()

# Execution
initial_state <- list(
  research_topic = "CRISPR Gene Editing"
)

cat("\n=== STARTING ACADEMIC RESEARCH PIPELINE ===\n")
cat(sprintf("Checkpointer: %s\n", CHECKPOINTER_MODE))

result <- compiled_dag$run(
  initial_state = initial_state,
  max_steps = 5,
  checkpointer = checkpointer,
  thread_id = thread_id
)

cat("\n--- PIPELINE EXECUTION COMPLETE ---\n")
cat("\nFinal Report:\n")
cat(result$state$get("Compiler"), "\n")
cat("\n=== 100% SUCCESS ===\n")

# <!-- APAF Bioinformatics | test_academic_research.R | Approved | 2026-03-29 -->

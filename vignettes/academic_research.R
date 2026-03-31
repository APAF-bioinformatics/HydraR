## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## -----------------------------------------------------------------------------
# ── USER CONFIGURATION ──────────────────────────────────────────
CHECKPOINTER_MODE <- "none" # "none" | "memory" | "rds" | "duckdb"
RDS_DIR <- "checkpoints"
DUCKDB_PATH <- "checkpoints/academic_research.duckdb"
THREAD_ID <- "academic_research_run_1"
# ────────────────────────────────────────────────────────────────

checkpointer <- switch(CHECKPOINTER_MODE,
  "memory" = MemorySaver$new(),
  "rds" = RDSSaver$new(dir = RDS_DIR),
  "duckdb" = {
    if (!dir.exists(dirname(DUCKDB_PATH))) dir.create(dirname(DUCKDB_PATH), recursive = TRUE)
    DuckDBSaver$new(db_path = DUCKDB_PATH)
  },
  "none" = NULL,
  stop(sprintf("Invalid CHECKPOINTER_MODE: '%s'", CHECKPOINTER_MODE))
)

thread_id <- if (!is.null(checkpointer)) THREAD_ID else NULL

## ----logic_registry-----------------------------------------------------------
research_logic_registry <- list(
  # 0. Initial Research Topic
  initial_state = list(
    research_topic = "CRISPR Gene Editing"
  ),

  # 1. Agent Roles
  roles = list(
    Searcher = "You are an academic research assistant. Identify 2-3 key hypothetical papers for the given topic. Output the result as a simple list.",
    Summarizer = "You are a scientific editor. Summarize the following paper list into key highlights.",
    Compiler = "You are a technical writer. Format the following summaries into a professional markdown report with headers."
  ),

  # 2. Prompt Builders
  prompts = list(
    Searcher = function(state) {
      sprintf("Research Topic: %s\nProvide a list of 2-3 paper titles and brief descriptions.", state$get("research_topic"))
    },
    Summarizer = function(state) {
      sprintf("Paper List: %s", state$get("Searcher"))
    },
    Compiler = function(state) {
      sprintf("Topic: %s\nSummaries: %s", state$get("research_topic"), state$get("Summarizer"))
    }
  )
)

## ----factory------------------------------------------------------------------
research_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (params$driver == "gemini") GeminiCLIDriver$new() else NULL

  AgentLLMNode$new(
    id = id,
    label = label,
    role = research_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = research_logic_registry$prompts[[id]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Searcher[Literature Searcher | driver=gemini] --> Summarizer
  Summarizer[Content Summarizer | driver=gemini] --> Compiler
  Compiler[Report Compiler | driver=gemini]
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = research_node_factory)
compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(compiled_dag$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat(sprintf("Starting Literature Pipeline (checkpointer: %s)...\n", CHECKPOINTER_MODE))
# 
# result <- compiled_dag$run(
#   initial_state = research_logic_registry$initial_state,
#   max_steps = 5,
#   checkpointer = checkpointer,
#   thread_id = thread_id
# )
# 
# cat("\n--- PIPELINE EXECUTION COMPLETE ---\n")
# cat(result$state$get("Compiler"), "\n")


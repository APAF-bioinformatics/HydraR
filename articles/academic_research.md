# Agentic Academic Researcher

## Introduction

This vignette demonstrates the **Academic Research** pattern using
`HydraR`. We define a linear, multi-stage agentic workflow designed to
synthesize academic literature into a final report using the **Gemini
CLI**.

The pipeline comprises three agents: 1. **Searcher Node**: Given a
research topic, finds relevant academic papers. 2. **Summarizer Node**:
Ingests the raw papers and extracts key findings. 3. **Compiler Node**:
Takes the extracted findings and formats them into a comprehensive
literature review.

## Setup

``` r
library(HydraR)

# Initialize the Gemini CLI driver
# Note: This assumes the 'gemini' CLI is installed and configured on your system.
driver <- GeminiCLIDriver$new()
```

## Checkpointer Configuration

HydraR supports optional state checkpointing after each node execution.
Choose from four modes:

- **`"none"`** – Ephemeral run, no persistence (default).
- **`"memory"`** – In-memory via `MemorySaver` (lost on session exit).
- **`"rds"`** – File-based via `RDSSaver` (lightweight, base R only).
- **`"duckdb"`** – Database-backed via `DuckDBSaver` (requires `duckdb`
  package).

``` r
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
```

## Building the DAG

Initialize the `AgentDAG`.

``` r
dag <- AgentDAG$new()
```

### 1. The Searcher Node

Utilizing an LLM to identify key papers for a topic.

``` r
searcher_node <- AgentLLMNode$new(
  id = "Searcher",
  label = "Literature Searcher",
  role = "You are an academic research assistant. Identify 2-3 key hypothetical papers for the given topic. Output the result as a simple list.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Research Topic: %s\nProvide a list of 2-3 paper titles and brief descriptions.", state$get("research_topic"))
  }
)

dag$add_node(searcher_node)
```

### 2. The Summarizer Node

Extracts value from the search results.

``` r
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
```

### 3. The Compiler Node

Drafts the final markdown report.

``` r
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
```

## Defining Transitions

Configure a straight-through pipeline:
`Searcher -> Summarizer -> Compiler`

``` r
dag$set_start_node("Searcher")

dag$add_edge("Searcher", "Summarizer")
dag$add_edge("Summarizer", "Compiler")

compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Visualizing the Workflow

``` r
cat("```mermaid\n")
```

``` mermaid
``` r
cat(compiled_dag$plot(type = "mermaid"))
```

graph TD Searcher\[“Literature Searcher”\] Summarizer\[“Content
Summarizer”\] Compiler\[“Report Compiler”\] Searcher –\> Summarizer
Summarizer –\> Compiler

``` r
cat("\n```\n")
```

    ## Running the Scenario

    Provide the topic and run the pipeline.


    ``` r
    initial_state <- list(
      research_topic = "CRISPR Gene Editing"
    )

    cat(sprintf("Starting Literature Pipeline (checkpointer: %s)...\n", CHECKPOINTER_MODE))
    result <- compiled_dag$run(
      initial_state = initial_state,
      max_steps = 5,
      checkpointer = checkpointer,
      thread_id = thread_id
    )

    cat("\n--- PIPELINE EXECUTION COMPLETE ---\n")
    cat(result$state$get("Compiler"), "\n")

The system successfully routed the data through all three agents to
build a consolidated report!

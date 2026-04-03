# Integrating HydraR with `targets`

This guide describes the strategy for combining **HydraR** agentic orchestration with the **`targets`** workflow management package [@targets]. The core principle is to treat `AgentDAG` executions as discrete, cached targets within a pipeline.

---

## 1. Macro-Orchestration (DAG-as-Target)

The simplest integration is to run an entire HydraR workflow within a single `tar_target`. This is ideal for long-running agentic tasks where you want to cache the final results of a multi-agent collaboration.

```r
# _targets.R
library(targets)
library(HydraR)

list(
  # A target representing a complete autonomous research agent
  tar_target(
    research_agent_results,
    {
      dag <- load_workflow("research_pipeline.yml")
      dag$compile()
      dag$run(initial_state = list(query = "bioinformatics trends"))
    },
    format = "rds" # Caches the entire results list (status, state, outputs)
  )
)
```

---

## 2. Micro-Orchestration (State-to-Target)

For more granular control, downstream targets can depend on specific parts of an agent's memory (the `AgentState`). This allows standard R functions to process agentic outputs as soon as they are available.

```r
# Extract only the summary content from the successful agent run
tar_target(
  literature_summary,
  research_agent_results$results$summary_node$output$content
)
```

---

## 3. Integrated Resilience & Checkpointing

Since HydraR features a built-in **DuckDB Checkpointer**, it can bridge with `targets` to provide "interrupt-safe" agentic execution. If a `targets` build is cancelled or fails, HydraR can resume from its last successful node within the target, rather than restarting the entire DAG.

### Resume Pattern
```r
tar_target(
  resilient_agent,
  {
    saver <- DuckDBSaver$new(db_path = "state_history.duckdb")
    dag$run(
      thread_id = "joss-demo-001",
      checkpointer = saver,
      resume_from = "last" # Automatically resume from the last successful checkpoint
    )
  }
)
```

---

## 4. Proposed Strategic Utility: `tar_hydra()`

To simplify this integration, we recommend implementing a native `tar_hydra()` wrapper in future releases of HydraR. This utility would automate:
1.  **Dependency Tracking**: Automatically scanning the `AgentDAG` for any R objects or files it depends on.
2.  **Metadata Linking**: Synchronizing `targets` metadata with the HydraR DuckDB history for a unified audit trail.
3.  **Parallelism**: Integrating `furrr` (HydraR's parallel backend) with `targets` asynchronous workers.

---
<!-- APAF Bioinformatics | HydraR | targets Integration | 2026-04-03 -->

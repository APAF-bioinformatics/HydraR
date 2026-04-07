# Case Study: Fault-Tolerant Pipelines with DuckDB Persistence

This case study explains how to use the **DuckDB checkpointer** for resilient, resumable workflows in `HydraR`.

## Overview

To mitigate transient failures inherent to long-running scientific workflows, `HydraR` integrates advanced checkpoint-and-resume functionality powered by **DuckDB**. 

Whenever a pipeline pauses mid-execution (e.g., due to a network error, API limit, or a "PAUSE" status from a logic node), it automatically persists its complete `AgentState`. Upon restart, the workflow can resume directly from the point of failure, actively preventing redundant evaluations and saving costly LLM invocations.

## Workflow Structure

The workflow follows a linear path where each step represents a state transition that is saved to the persistent database.

![Fault Workflow DAG](../man/figures/fault_workflow.png)
*Figure 1: Visual logic of the fault-tolerant pipeline with DuckDB persistence, illustrating a linear flow with restartable checkpoints.*

## Execution Pattern (Checkpoint and Resume)

The following R code demonstrates how a session can be paused and later resumed using its unique `thread_id`:

```r
library(HydraR)
wf    <- load_workflow("state_persistence.yml")
dag   <- spawn_dag(wf)
saver <- DuckDBSaver$new(db_path = "history.duckdb")
tid   <- "reprex-session-001"

# Run 1: Pauses at Step2 — state is automatically saved to DuckDB
res1 <- dag$run(
  thread_id = tid, 
  checkpointer = saver,
  initial_state = list(fixed = FALSE)
)

# Run 2: Fix applied, workflow resumes from Step2
res2 <- dag$run(
  thread_id = tid, 
  checkpointer = saver,
  initial_state = list(fixed = TRUE),
  resume_from = "Step2"
)
```

## Resilience in Data Science

By safeguarding computational progress autonomously, this pattern effectively circumvents prohibitively costly re-execution in data science pipelines reliant on voluminous LLM invocations or laborious large-scale database queries.

---

## Technical Source
The full implementation details, including the DuckDB configuration and session management, can be found in the source vignette:

- **Source Vignette**: [state_persistence.Rmd](state_persistence.Rmd)

<!-- APAF Bioinformatics | HydraR | Approved -->

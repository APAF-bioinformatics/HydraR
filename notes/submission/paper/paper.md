---
title: 'HydraR: Stateful Agentic Orchestration for Scientific Reproducibility in R'
tags:
  - R
  - LLM
  - Agents
  - Reproducibility
  - Bioinformatics
  - Git
authors:
  - name: Chi Nam Ignatius Pang
    orcid: 0000-0001-9703-5741
    affiliation: 1
  - name: Aidan Tay
    orcid: 0000-0003-1315-4896
    affiliation: 1
affiliations:
 - index: 1
   name: Australian Proteome Analysis Facility (APAF), Macquarie University, Sydney, Australia
date: 31 March 2026
repository: https://github.com/APAF-bioinformatics/HydraR
bibliography: paper.bib
---

# Summary

`HydraR` is a lightweight, state-managed framework for orchestrating complex "agentic" workflows—multi-step processes driven by Large Language Models (LLMs)—directly within R. While mainstream tools such as LangChain [@langchain] and CrewAI [@crewai] are Python-native, `HydraR` addresses the R community's needs for reproducibility, auditability, and integration with existing statistical pipelines.

Researchers design workflows as Directed Acyclic Graphs (DAGs) or iterative state machines, where each node is an LLM-driven prompt, an R function, or an autonomous auditor. `HydraR` supports both cloud APIs (Gemini, Claude, OpenAI) and local CLI tools (Ollama, Gemini CLI).

# Statement of Need

The R ecosystem lacks a unified framework providing both high-level agentic orchestration and low-level filesystem safety. Existing packages like `ellmer` [@ellmer] focus on chat interfaces, while `mall` [@mall] maps LLM calls over data frames. Neither manages long-running, multi-agent collaborations requiring state persistence or isolated execution.

`HydraR` solves three critical problems:
1. **Auditability**: A centralized `AgentState` with persistent checkpointing (DuckDB [@duckdb]) provides a full audit trail of every LLM interaction and state mutation.
2. **Filesystem Safety**: **Git Worktrees** isolate each parallel agent's execution into a temporary branch, preventing race conditions during multi-agent collaboration.
3. **Reproducible Orchestration**: Workflows defined via **Mermaid.js** syntax and **YAML** manifests decouple logic from R code, enabling portable, shareable agentic protocols without multi-language environment management.

# State of the Field

While `reticulate` [@reticulate] allows R users to access Python frameworks like LangChain, this introduces impedance mismatch when serializing complex R data structures across the language boundary. `HydraR` is built natively on R6 [@R6], preserving full fidelity of statistical objects and R's integrated debugging tools. Unlike `ellmer` [@ellmer] (chat-centric, no DAG orchestration) and `gptstudio` [@gptstudio] (IDE-centric coding assistance), `HydraR` manages the full lifecycle of headless, multi-agent collaborations with persistent checkpointing.

# Software Design

`HydraR` follows a modular R6 architecture:
- **AgentLLMNode / AgentLogicNode**: LLM-driven prompts and pure R logic steps, respectively, with pluggable `AgentDriver` backends for provider-agnostic communication.
- **AgentDAG**: Core orchestrator managing node dependencies, validation via `igraph` [@igraph], and parallel execution via `furrr` [@furrr].
- **AgentState**: Centralized state with versioned history and reducers to harmonize multi-agent outputs.
- **WorktreeManager**: Spawns isolated Git worktrees per parallel task, with a **ConflictResolver** for automated or human-in-the-loop merge reconciliation.

# Research Applications

## Travel Itinerary Planner
A `Planner` LLM agent generates an itinerary while a `Validator` logic node audits it against user-defined constraints. **Conditional looping** between the two nodes forces iterative refinement until all constraints are satisfied, demonstrating self-correcting state machines.

### Declarative Workflow Excerpt
```yaml
graph: |
  graph TD
    Planner["Travel Planner | type=llm | role_id=travel_concierge"]
    Validator["Constraint Auditor | type=logic | logic_id=validate_constraints"]
    
    Planner --> Validator
    Validator -- "fail" --> Planner

roles:
  travel_concierge: >
    You are a professional travel concierge. Create detailed, day-by-day itineraries...
```

### R Orchestration (Minimal)
```r
library(HydraR)
wf <- load_workflow("hong_kong_travel.yml")
dag <- spawn_dag(wf, auto_node_factory())
results <- dag$run(initial_state = wf$initial_state)
```

## Parallel Sorting Algorithm Comparison
Three LLM agents simultaneously implement sorting algorithms in isolated Git worktrees, preventing filesystem conflicts. A **Merge Harmonizer** reconciles the branches, and a benchmarker evaluates performance over 5 trials (\autoref{fig:sorting}).

![Sorting Algorithm Performance Benchmark (1,000 elements over 5 trials).](sorting_benchmark.pdf){#fig:sorting}

### Declarative Workflow Excerpt
```yaml
graph: |
  graph TD
      bubble["Bubble Agent | type=llm | role_id=bubble"]
      quick["Quick Agent | type=llm | role_id=quick"]
      merge["Merge Agent | type=llm | role_id=merge"]
      merger["Merge Harmonizer | type=merge"]
      benchmark["Benchmark | type=logic | logic_id=run_benchmark"]

      bubble --> merger
      quick --> merger
      merge --> merger
      merger --> benchmark
```

### R Orchestration (Parallel with Isolation)
```r
library(HydraR)
wf <- load_workflow("sorting_benchmark.yml")
dag <- spawn_dag(wf, auto_node_factory())
results <- dag$run(initial_state = wf$initial_state, use_worktrees = TRUE)
```

## Fault-Tolerant Pipelines with DuckDB Persistence
`HydraR` provides checkpoint-and-resume via DuckDB [@duckdb]. A paused pipeline persists its full `AgentState`; on restart, the operator's fix is merged into the restored state and execution resumes from the paused node, skipping completed steps.

### Inline Workflow Definition
```r
library(HydraR)
register_logic("check_fixed", function(state) {
  if (!isTRUE(state$get("fixed")))
    return(list(status = "pause", output = "Waiting for manual fix."))
  list(status = "success", output = "System recovered!")
})

dag <- mermaid_to_dag('
  graph TD
    Step1["Initialization | type=logic | logic_id=init_proc"]
    Step2["Risky Logic | type=logic | logic_id=check_fixed"]
    Step3["Conclusion | type=logic | logic_id=finalize_proc"]
    Step1 --> Step2
    Step2 --> Step3
')
```

### Checkpoint and Resume
```r
saver <- DuckDBSaver$new(db_path = tempfile(fileext = ".duckdb"))
tid   <- "reprex-session-001"

# Run 1: Pauses at Step2 — state saved to DuckDB
res1 <- dag$run(thread_id = tid, checkpointer = saver,
                initial_state = list(fixed = FALSE))

# Run 2: Fix applied, resume from Step2
res2 <- dag$run(thread_id = tid, checkpointer = saver,
                initial_state = list(fixed = TRUE),
                resume_from = "Step2")
# res2$results$Step3$output => "All steps finished."
```

This pattern avoids costly re-execution in pipelines with expensive LLM calls or long-running queries.

# Research Impact Statement

`HydraR` is used at the **Australian Proteome Analysis Facility (APAF)** to automate bioinformatics workflow development. Its declarative YAML definitions allow domain experts to audit logic without R proficiency, enabling scalable and reproducible LLM-assisted research.

# AI Usage Disclosure

A significant portion of `HydraR` was developed using **Antigravity**, an agentic AI coding assistant, following a strict "Human-in-the-loop" pattern. Human authors designed the architecture; AI implemented logic blocks, tests, and documentation. All AI-generated code was manually reviewed and tested.

# Acknowledgements

We acknowledge funding from **Bioplatforms Australia**, enabled by the **National Collaborative Research Infrastructure Strategy (NCRIS)**.

# References

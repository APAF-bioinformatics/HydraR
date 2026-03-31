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

`HydraR` is a lightweight, state-managed framework for orchestrating complex "agentic" workflows—multi-step processes driven by Large Language Models (LLMs)—directly within the R environment. While mainstream agentic tools such as LangChain [@langchain] or CrewAI [@crewai] are predominantly Python-native, `HydraR` addresses the specific needs of the R community, particularly in scientific research where reproducibility, auditability, and integration with existing R-based statistical pipelines are paramount.

The software enables researchers to design workflows as Directed Acyclic Graphs (DAGs) or iterative state machines. Each "node" in the graph represents a logic step, which can be an LLM-driven prompt, a hardcoded R function, or an autonomous auditor. `HydraR` prioritizes high-fidelity interactions with both cloud-based APIs (e.g., Gemini, Claude, OpenAI) and local Command Line Interface (CLI) tools, ensuring that agentic operations are as robust and reproducible as traditional scripts.

# Statement of Need

The rapid advancement of LLMs has introduced the "agentic" paradigm, where AI agents autonomously reason through tasks, call tools, and iterate on solutions. However, the R ecosystem lacks a unified framework that provides both high-level orchestration and low-level filesystem safety. Existing packages like `ellmer` [@ellmer] focus on interactive chat interfaces, while `mall` [@mall] excels at mapping LLM calls over data frames. Neither is built to manage long-running, multi-agent collaborations that require complex state persistence or isolated execution environments.

`HydraR` solves three critical problems for the research community:
1. **Nondeterminism vs. Auditability**: By implementing a centralized `AgentState` with persistent checkpointing (SQLite/DuckDB), `HydraR` provides a full audit trail of every LLM interaction, state mutation, and decision point.
2. **Filesystem Safety in Parallel Workflows**: Many agents are designed to modify code or data directly. Running these in parallel often leads to race conditions. `HydraR` introduces the use of **Git Worktrees** to isolate every agent's execution into a unique, temporary branch, preventing state corruption during multi-agent collaboration.
3. **Reproducible Orchestration**: By allowing workflows to be defined using **Mermaid.js** syntax and **YAML** manifests, `HydraR` decouples the "logic" of the agentic workflow from the R code that executes it. This "R-Native" approach ensures high **portability**, allowing complex agentic protocols to be shared as standard R scripts or bundled into R packages without the complexities of multi-language environment management. For the R community, a native framework also significantly lowers the **learning curve** by removing the need to master Python-specific paradigms, and facilitates **communication and sharing** within existing research groups through familiar R-based version control and peer-review workflows.

# State of the Field

In the Python ecosystem, frameworks like LangChain and CrewAI provide extensive libraries for agentic work. While `reticulate` [@reticulate] allows R users to access these tools, this "two-language" approach often introduces an impedance mismatch where complex R data structures must be serialized and translated across the language boundary. `HydraR` is built natively on the R6 object-oriented system [@R6], ensuring that researchers can leverage R's integrated debugging tools (`browser()`), maintain full fidelity of statistical objects in the `AgentState`, and benefit from R's inherent **LLM-readiness**. Modern generative models are highly proficient in R, making the generation of R-native logic nodes both reliable for automation and easy for human researchers to audit. Unlike `ellmer` [@ellmer], which provides a chat-centric interface without DAG-based orchestration or persistent checkpointing, `HydraR` manages the full lifecycle of multi-agent collaborations. It also differs from `gptstudio` [@gptstudio], which targets IDE-centric coding assistance, by prioritizing **headless automation** and reproducible research pipelines.

# Software Design

`HydraR` follows a modular R6 architecture:
- **AgentLLMNode**: Drives LLM interactions via a pluggable `AgentDriver`. It manages prompt construction, response parsing, and code extraction, storing results in the shared `AgentState`.
- **AgentLogicNode**: Executes arbitrary R code to evaluate the workflow state, determine logical outcomes (e.g., "success" or "fail"), and dynamically control the execution path. This enables the integration of deterministic statistical checks and data visualizations directly into agentic reasoning loops.
- **AgentDAG**: The core orchestrator that manages node dependencies, validation (e.g., circular dependency checks via `igraph` [@igraph]), and parallel execution via `furrr` [@furrr].
- **AgentState**: A centralized "single source of truth" for the workflow. It supports versioned history and complex reducers to harmonize outputs from multiple agents.
- **AgentDriver**: An abstraction layer for LLM communication. This allows `HydraR` to be provider-agnostic, supporting local CLIs (Ollama, Gemini CLI) or cloud APIs via `httr2`.
- **GitWorktree**: A specialized engine for isolated execution. It spawns a new Git worktree for each parallel task, executes the agent logic in that isolated context, and merges the results back using a **Merge Harmonizer**.
- **ConflictResolver**: An extensible system that provides a range of merging techniques, from **automated semantic resolution** using LLMs to **manual interventions** (Human-In-The-Loop) that pause execution for complex conflict reconciliation.

# Research Applications

## Travel Itinerary Planner
This example demonstrates high-fidelity orchestration in a non-coding context. The workflow uses the `GeminiCLIDriver` to drive a `Planner` agent that generates a detailed itinerary and a `Validator` agent that audits it against user-defined constraints. A critical feature is the **conditional looping** between these two nodes. If the `Validator` logic node detects that specific constraints (e.g., must-include locations) are missing from the itinerary, it triggers a "fail" transition that forces the `Planner` to iteratively refine the output. This illustrates `HydraR`'s ability to transition from simple linear execution to complex, self-correcting state machines.

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
This benchmarking example illustrates the framework's "repo-modifying" capabilities. Three agents (Bubble, Quick, Merge sort agents) are simultaneously tasked with implementing sorting functions for a dataset of **1,000 random numbers**. `HydraR` spawns three isolated Git worktrees, allowing the agents to "write" to the same repository root without conflicts. A downstream **Merge Harmonizer** node then reconciles these independent branches. Finally, a benchmarker executes **5 trials** for each algorithm to evaluate performance (\autoref{fig:sorting}). This entire cycle demonstrates the framework's flexibility in managing autonomous code generation and scientific validation pipelines.

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
Long-running scientific workflows are susceptible to transient failures—API timeouts, resource exhaustion, or intermediate data validation errors. `HydraR` addresses this with a checkpoint-and-resume architecture backed by DuckDB [@duckdb]. In this minimal example, a 3-step pipeline encounters a recoverable failure at `Step2`, which **pauses** execution and persists the full `AgentState` to a DuckDB database. After a human operator corrects the state (setting a `fixed` flag to `TRUE`), execution resumes from the paused node using the same `thread_id`. The checkpointer merges the operator's fix into the restored state, ensuring that previously completed steps (e.g., `Step1`) are not re-executed.

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

This pattern is particularly valuable for bioinformatics pipelines where individual LLM calls or database queries may cost minutes to complete, making full re-execution prohibitively expensive.

# Research Impact Statement

`HydraR` is currently being used at the **Australian Proteome Analysis Facility (APAF)** to automate complex bioinformatics software development, agenting workflow development and testing. Its ability to provide a "Zero-R-Code" declarative definition (via YAML) allows bioinformaticians to define logic that can be audited by domain experts who may not be proficient in R. By lowering the barrier to entry for robust agentic workflows, `HydraR` enables a new class of LLM-assisted scientific research that is both scalable and reproducible.

# AI Usage Disclosure

Transparency is a core value of the `HydraR` project. A significant portion of this package was developed using **Antigravity**, an agentic AI coding assistant. The development followed a strict "Human-in-the-loop" pattern: human authors designed the core architecture and R6 patterns, while Antigravity was used to implement specific logic blocks, unit tests, and documentation. Every line of code generated by AI was manually reviewed, modified, and tested by the human authors to ensure adherence to APAF Bioinformatics standards.

# Acknowledgements

We acknowledge funding from **Bioplatforms Australia**, enabled by the **National Collaborative Research Infrastructure Strategy (NCRIS)**.

# References

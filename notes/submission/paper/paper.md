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

`HydraR` is a lightweight, state-managed framework designed to orchestrate complex "agentic" workflows—autonomous, multi-step processes driven by Large Language Models (LLMs)—natively within R. While mainstream orchestration tools such as LangChain [@langchain] and CrewAI [@crewai] are predominantly Python-based, `HydraR` fulfills the R community's critical requirements for rigorous reproducibility, auditability, and seamless integration with established statistical pipelines.

Researchers can architect workflows as Directed Acyclic Graphs (DAGs) or iterative state machines, wherein each node represents an LLM-prompted task, a deterministic R function, or an autonomous auditor. `HydraR` ensures broad compatibility by supporting both complex cloud APIs (Gemini, Claude, OpenAI) and local CLI models (Ollama, Gemini CLI).

# Statement of Need

The contemporary R ecosystem currently lacks a unified framework that provides both high-level agentic orchestration and robust, low-level filesystem safety. Existing packages, such as `ellmer` [@ellmer], primarily focus on conversational interfaces, while `mall` [@mall] excels at mapping LLM inferences over data frames. Neither is structurally equipped to manage long-running, multi-agent collaborations that demand complex state persistence or isolated execution environments.

`HydraR` addresses three fundamental challenges in this domain:
1. **Auditability**: It implements a centralized `AgentState` with persistent checkpointing (via DuckDB [@duckdb]), yielding a complete, verifiable audit trail of all LLM interactions and state mutations.
2. **Filesystem Safety**: Leveraging **Git Worktrees**, `HydraR` isolates parallel agent executions into temporary branches, virtually eliminating data corruption and race conditions during concurrent operations.
3. **Reproducible Orchestration**: By defining workflows via **Mermaid.js** syntax and **YAML** manifests, `HydraR` decouples orchestration logic from the underlying execution framework. This declarative approach creates portable, shareable agentic protocols, effortlessly bypassing the fragility typical of multi-language environments.

# State of the Field

Although `reticulate` [@reticulate] enables R users to interface with Python frameworks like LangChain, doing so introduces a structural impedance mismatch when serializing complex R data objects across language boundaries. `HydraR` avoids this by building natively on the R6 object-oriented system [@R6], preserving the fidelity of statistical objects while allowing direct compatibility with R's integrated debugging tool chains. Furthermore, unlike `ellmer` [@ellmer] (which offers chat-centric workflows without DAG orchestration), and `gptstudio` [@gptstudio] (which serves as an IDE-centric coding assistant), `HydraR` is specifically engineered to manage the complete lifecycle of headless, parallel, multi-agent collaborations replete with robust state retention.

# Software Design

`HydraR` employs a highly modular R6 architecture spanning several key components:
- **AgentLLMNode / AgentLogicNode**: Encapsulate LLM-driven prompts and deterministic pure-R logic steps, respectively. They utilize pluggable `AgentDriver` backends for provider-agnostic model communication.
- **AgentDAG**: The core orchestration engine that manages node dependencies, validates network topology (via `igraph` [@igraph]), and executes logic in parallel (via `furrr` [@furrr]).
- **AgentState**: A centralized state repository employing versioned history and custom reducers to systematically coordinate multi-agent outputs.
- **WorktreeManager**: An engine that provisions isolated Git worktrees for parallel execution tasks, paired with an extensible **ConflictResolver** handling automated semantic resolution alongside human-in-the-loop task reconciliation.

# Research Applications

## Travel Itinerary Planner
In this example, an LLM `Planner` agent intelligently generates a draft itinerary, while a deterministic `Validator` logic node actively audits the output against user-defined constraints. Crucially, **conditional looping** between these entities enforces an iterative refinement cycle until all strict parameters are met, thereby operationalizing the concept of a self-correcting state machine within R.

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
This benchmarking example tasks three distinct LLM agents with simultaneously implementing different sorting algorithms. `HydraR` executes each task within an isolated Git worktree to aggressively uncouple filesystem side-effects and prevent merge conflicts. Following execution, a **Merge Harmonizer** systematically reconciles the independent branches back to the main state, preceding a terminal logic node that empirically benchmarks the aggregated algorithms across five continuous trials (\autoref{fig:sorting}).

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
To mitigate transient failures inherent to long-running scientific workflows, `HydraR` integrates advanced checkpoint-and-resume functionality powered by DuckDB [@duckdb]. Whenever a pipeline pauses mid-execution, it automatically persists its complete `AgentState`. Upon restart, any operator-applied programmatic interventions are seamlessly merged, actively preventing redundant evaluations by allowing execution to jump directly back to the paused node.

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

By safeguarding computational progress autonomously, this pattern effectively circumvents prohibitively costly re-execution in bioinformatics pipelines reliant on voluminous LLM invocations or laborious large-scale database queries.

# Research Impact Statement

`HydraR` is actively deployed at the **Australian Proteome Analysis Facility (APAF)** to architect and automate resilient bioinformatics tooling. Its declarative YAML schemas empower non-programming domain experts to routinely govern advanced LLM logic pipelines without any R coding proficiency, thereby democratizing the scale and reproducibility of model-assisted scientific research.

# AI Usage Disclosure

Transparency and accountability are core tenets of the `HydraR` paradigm. A substantial portion of the implementation was co-developed utilizing **Antigravity**, an agentic AI coding assistant, supervised by a rigorous "human-in-the-loop" review protocol. Specifically, the original authors independently conceptualized the underlying system architecture, while the AI generated specialized logic, unit tests, and software documentation with every resultant commit sequentially tested and manually verified.

# Acknowledgements

We acknowledge funding from **Bioplatforms Australia**, enabled by the **National Collaborative Research Infrastructure Strategy (NCRIS)**.

# References

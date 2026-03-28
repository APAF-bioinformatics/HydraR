# HydraR: Stateful Agentic Orchestration for R

`HydraR` is a lightweight, state-of-the-art orchestrator for building agentic workflows in R. It prioritizes **CLI-native LLM interactions**, **hardened state management**, and **graph-based execution** (supporting both Directed Acyclic Graphs and iterative loops).

Unlike API-heavy frameworks, `HydraR` is designed to orchestrate complex tasks by driving external CLI tools (like `gemini-cli`, `claude-code`, or `gh copilot`) as first-class citizens.

## Key Features

- **📍 Graph Orchestration**: Define complex agentic workflows using `AgentDAG` with support for parallel execution (`furrr`) and conditional loops.
- **💾 Centralized State**: `AgentState` provides a single source of truth for all nodes, with support for complex reducers and history management.
- **🕒 Persistent Checkpointing**: Resumable execution threads via `Checkpointer` (supporting SQLite/DuckDB).
- **🖥️ CLI-First Drivers**: High-fidelity drivers for local and provider-based CLIs, ensuring tool calls and environment discovery are robust.
- **📊 Mermaid Visualization**: Export your agent's logic directly to Mermaid.js syntax for interactive documentation.
- **🛡️ Validation Engine**: Integrated compile-time checks for undefined nodes, circular dependencies, and unreachable states.
- **🏷️ Node Labeling**: Support for human-readable labels in DAG nodes, independent of their unique IDs.

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("apaf-bioinformatics/HydraR")
```

## "Hello World" Example

```r
library(HydraR)

# 1. Define a simple logic node
node_hello <- AgentLogicNode$new(
    id = "hello_world",
    logic_fn = function(state) {
        input_text <- state$get("input")
        list(status = "SUCCESS", output = list(message = paste("Hello", input_text)))
    }
)

# 2. Build the orchestrator
dag <- AgentDAG$new()
dag$add_node(node_hello)
dag$compile()

# 3. Execute
results <- dag$run(initial_state = list(input = "Hydra"))
print(results$results$hello_world$output$message)
# [1] "Hello Hydra"

# 4. Round-Trip Visualization
dag$plot(type = "mermaid")
# Outputs Mermaid syntax using node labels if provided
```

## APAF Standards

This project adheres to the **APAF Bioinformatics** standards for agentic reproducibility and software hardness.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-29 -->

# Design Thinking in HydraR

The development of `HydraR` was guided by the need for a robust, reproducible, and scalable framework for agentic orchestration in R, specifically for scientific and bioinformatics research. This document outlines the key design decisions and trade-offs made during development.

## 🏛️ Core Architecture: Orchestration vs. Execution

One of the primary design choices was the strict separation between the **Orchestrator** (`AgentDAG`) and the **Executors** (`AgentDriver`).

*   **Logic**: The DAG manages the flow of state and the decision-making graph.
*   **Execution**: Drivers handle the actual interaction with external LLMs or local tools.
*   **Trade-off**: This adds complexity to the R6 class hierarchy but ensures that the package is provider-agnostic. You can swap a Claude-based driver for a Gemini-based one without changing the workflow logic.

## 🖥️ CLI-First Philosophy

Unlike many other frameworks that prioritize the latest REST API wrappers, `HydraR` prioritizes **CLI interactions**.

*   **Why?**: Scientific environments often have limited egress or require specific local environment discovery (like `path` resolution) that CLIs handle better than raw HTTP calls. CLIs like `gemini-cli` or `claude-code` also manage their own authentication and retry logic more robustly.
*   **Trade-off**: This requires the user to have specific CLI tools installed, but it significantly reduces the maintenance burden of the R package itself.

## 🌲 Git Worktree Isolation

For tasks involving file modifications (e.g., automated code fixing), `HydraR` uses **Git Worktrees** to provide isolated execution environments.

*   **Why?**: Orchestrating multiple agents in parallel on the same directory leads to race conditions and inconsistent states. Worktrees allow each agent (or node) to operate on its own branch/copy of the repository without interfering with the others.
*   **Design Choice**: We chose Worktrees over Docker containers to keep the framework "R-native" and avoid the overhead of container management in HPC environments.

## 💾 Hardened State & Persistence

`HydraR` uses `AgentState` backed by high-performance SQL (DuckDB or SQLite).

*   **Decision**: Moving away from complex nested R lists to a tabular/relational state model ensures that checkpoints are durable and can be audited after the run.
*   **Merit**: This enables "Time-Travel Debugging" where a researcher can inspect the exact state of the workflow at any given node transition.

## 📊 Human-in-the-loop: Mermaid Visualization

The `mermaid_parser.R` integration was designed to make complex agentic graphs "human-readable" by default.

*   **Philosophy**: If a researcher cannot visualize the agent's logic, they cannot trust it. By supporting round-trip Mermaid syntax, we allow users to design in a visual editor and execute in R, or vice versa.

## 🛡️ Scalability & Validation

The integrated **Validation Engine** checks for undefined nodes and circular dependencies *before* execution starts.

*   **Impact**: This prevents expensive mid-run failures in long-running agentic pipelines.

## 🖋️ Scholarly Design & Strategy
The core R6 architecture, state management patterns, and Git worktree isolation strategies were designed and authored by the human authors (Ignatius Pang and Aidan Tay) during a focused **4–5 day architectural sprint** and then **rigorously tested manually**. 

AI assistance (via Antigravity) was strategically employed for the implementation of redundant logic blocks, standard unit tests, and documentation hardening, while architectural integrity and design trade-offs remained human-led.

### Public Disclosure Timeline & Reproducibility
To balance the goals of open-source transparency with the risk of scientific "scooping," the development team has adopted the following release strategy:
1.  **ArXiv Preprint**: Early disclosure of the stateful agentic orchestration protocol.
2.  **rOpenSci Submission**: Simultaneous public release and peer review.
3.  **JOSS Submission**: Final scholarly archival (6 months after public release), documenting the community review and hardening period.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-31 -->

# HydraR 0.1.0 (Initial Release)

- **Agentic Orchestration**: Implementation of the `AgentDAG` R6 class for managing complex directed workflows and iterative loops (state machines).
- **Hardened State Management**: Introduced the `AgentState` system, transitioning from nested R lists to a robust key-value store with support for complex reducers and history tracking.
- **Provider-Agnostic Drivers**: Initial support for `GeminiCLIDriver`, `ClaudeCodeDriver`, and `CopilotCLIDriver`, enabling "hot-swappable" LLM backends.
- **Git Worktree Isolation**: Developed the `worktree.R` module to provide safe, parallel execution environments for file-modifying agentic workflows.
- **High-Fidelity Validation**: Integrated `Auditor` and `Harmonizer` patterns for autonomous quality control and merging of distributed agent outputs.
- **Persistence & Checkpointing**: DuckDB and SQLite-backed `AgentCheckpointer` implemented for resumable and auditable execution.
- **Mermaid Round-Trip**: Visual design engine for converting between R objects and Mermaid.js syntax, enabling human-in-the-loop auditability.
- **AI Transparency**: Disclosure of LLM usage in development through `agents.md` and `DESIGN.md`.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-31 -->

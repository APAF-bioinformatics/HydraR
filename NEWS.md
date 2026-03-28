# HydraR 0.1.0

- **Initial Release** of the HydraR framework for stateful agentic orchestration in R.
- **AgentDAG**: Core graph execution machine with support for parallel nodes (`furrr`) and conditional loops.
- **AgentState**: Centralized R6-based state store with reducer support and immutable-style updates.
- **Checkpointer**: Persistent execution threads using SQLite/DuckDB/In-Memory backends.
- **CLI Drivers**: Integrated drivers for `Gemini`, `Claude`, `Copilot`, and `Ollama` via system CLIs.
- **Standardization**: Migrated from `RforRobot` (v0.x) to a standalone library with APAF Bioinformatics standards.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-29 -->

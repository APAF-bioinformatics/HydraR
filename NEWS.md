# HydraR 0.2.0 (Standardized Drivers)

- **Standardized Driver Architecture**: Renamed all core AI drivers for internal consistency and Provider + Mode clarity (e.g., `AnthropicCLIDriver`, `AnthropicAPIDriver`, `OpenAIAPIDriver`).
- **OpenAI Shorthand Refactor**: Swapped `driver=openai` to favor the high-performance **Codex CLI** as the default, with `driver=openai_api` for cloud reasoning.
- **Anthropic Shorthand Update**: Renamed `driver=claude` to **`driver=anthropic`** to match provider-first naming standards.
- **Improved GPT-5.4 Support**: Updated the `OpenAIAPIDriver` defaults for seamless integration with GPT-5.4 flagship/mini models.
- **Flagship Orchestration Vignette**: Introduced the [Advanced Orchestration 2026](file:///Users/ignatiuspang/Workings/2026/HydraR/notes/unmaintained_vignettes/advanced_orchestration_2026.Rmd) flagship documentation.
- **R6 Standards**: Resolved internal `finalize()` warnings to ensure full compliance with R6 2.4.0+ and suppressed developmental noise.

# HydraR 0.1.0 (Initial Release)

- **Agentic Orchestration**: Implementation of the `AgentDAG` R6 class for managing complex directed workflows and iterative loops (state machines).
- **Hardened State Management**: Introduced the `AgentState` system, transitioning from nested R lists to a robust key-value store with support for complex reducers and history tracking.
- **Provider-Agnostic Drivers**: Initial support for `GeminiCLIDriver`, `AnthropicCLIDriver`, and `CopilotCLIDriver`, enabling "hot-swappable" LLM backends.
- **Git Worktree Isolation**: Developed the `worktree.R` module to provide safe, parallel execution environments for file-modifying agentic workflows.
- **High-Fidelity Validation**: Integrated `Auditor` and `Harmonizer` patterns for autonomous quality control and merging of distributed agent outputs.
- **Persistence & Checkpointing**: DuckDB and SQLite-backed `AgentCheckpointer` implemented for resumable and auditable execution.
- **Mermaid Round-Trip**: Visual design engine for converting between R objects and Mermaid.js syntax, enabling human-in-the-loop auditability.
- **AI Transparency**: Disclosure of LLM usage in development through `agents.md` and `DESIGN.md`.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-31 -->

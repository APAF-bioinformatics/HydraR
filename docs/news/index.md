# Changelog

## HydraR 0.1.0 (Initial Release)

- **Agentic Orchestration**: Implementation of the `AgentDAG` R6 class
  for managing complex directed workflows and iterative loops (state
  machines).
- **State Management**: Robust `AgentState` system for tracking data
  through multi-step agent transitions.
- **Provider-Agnostic Drivers**: Initial support for `GeminiCLIDriver`,
  `AnthropicCLIDriver`, and `CopilotCLIDriver`, enabling “hot-swappable”
  LLM backends.
- **High-Fidelity Validation**: Integrated `Auditor` pattern for
  autonomous quality control of agent outputs.
- **Persistence**: DuckDB-backed `AgentCheckpointer` for stateful
  execution and recovery.

------------------------------------------------------------------------

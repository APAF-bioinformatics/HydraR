# HydraR Roxygen Examples Audit (v0.2.2)

This document provides a summary of the Roxygen `@examples` blocks currently present in the `HydraR` source code for the requested 55 functions and classes. 

> [!NOTE]
> All requested functions/classes have been updated with comprehensive, parameter-rich examples. Most are wrapped in `\dontrun{}` as they involve external CLI tools, APIs, or filesystem operations.

| Function / Class | Source File | Example Summary |
| :--- | :--- | :--- |
| `add_llm_node` | `R/factory.R` | API/CLI agent creation with model overrides & tool discovery |
| `add_logic_node` | `R/factory.R` | R logic node for validation (quality gates) and data cleaning |
| `AgentBashNode` | `R/node_languages.R` | Dynamic shell script generation using state variables |
| `AgentMapNode` | `R/map_node.R` | Batch processing over state lists with parallel execution |
| `AgentObserverNode` | `R/observer_node.R` | Side-effect monitoring and runtime telemetry |
| `AgentPythonNode` | `R/node_languages.R` | Reticulate-powered Python nodes with cross-language state |
| `AgentRouterNode` | `R/router_node.R` | Dynamic DAG routing based on semantic evaluation |
| `AgentTool` | `R/tools.R` | Tool definition for genomic searches with parameter schemas |
| `AnthropicAPIDriver` | `R/drivers_api.R` | JSON mode, temperature, and generation config for Claude |
| `AnthropicCLIDriver` | `R/drivers_cli.R` | CLI-based interaction with Claude using specific profiles |
| `Checkpointer` | `R/checkpointer.R` | Abstract interface for RDS and DuckDB session persistence |
| `cleanup_jules_branches`| `R/git_cleanup.R` | Automated cleanup of stale GitHub bot branches |
| `ConflictResolver` | `R/worktree.R` | LLM-driven semantic conflict resolution during merges |
| `CopilotCLIDriver` | `R/drivers_cli.R` | Integration with GitHub Copilot CLI for code generation |
| `dag_add_llm_node` | `R/factory.R` | Chaining LLM agents using the functional pipe API |
| `dag_add_logic_node` | `R/factory.R` | Interleaving R logic into parallel LLM workflows |
| `dag_create` | `R/factory.R` | Full DAG initialization with persistent audit logging |
| `DriverRegistry` | `R/driver_registry.R` | Centralized management and auditing of LLM drivers |
| `DuckDBMessageLog` | `R/message_log.R` | Production-grade audit trails with DuckDB persistence |
| `extract_r_code_advanced`| `R/utils.R` | Robust R code extraction from noisy LLM responses |
| `format_toolset` | `R/tools.R` | Prompt-ready formatting of tool schemas for agents |
| `GeminiAPIDriver` | `R/drivers_api.R` | JSON mode and safety filters for Gemini Pro |
| `GeminiCLIDriver` | `R/drivers_cli.R` | Multi-modal MCP tool usage and YOLO mode for Gemini |
| `GeminiImageDriver` | `R/drivers_api.R` | High-fidelity image generation (Imagen) for visualization |
| `get_agent_roles` | `R/registry.R` | Auditing all active personas in the global registry |
| `get_default_driver` | `R/driver_registry.R` | Resolving the global fallback driver for LLM nodes |
| `get_driver_registry` | `R/driver_registry.R` | Accessing the package-wide driver singleton |
| `get_logic` | `R/registry.R` | Dynamic retrieval of registered logic for node factories |
| `get_role_prompt` | `R/driver_registry.R` | Resolving technical identity prompts from the registry |
| `get_role` | `R/registry.R` | Role resolution for manual node construction |
| `init_bot_history` | `R/init_duckdb.R` | APAF-standard telemetry database initialization |
| `is_named_list` | `R/utils.R` | Validation of state updates and parameter records |
| `JSONLMessageLog` | `R/message_log.R` | Fast, atomic JSONL logging for parallel worktrees |
| `list_logic` | `R/registry.R` | Audit check of all available custom R logic functions |
| `load_workflow` | `R/registry.R` | Multi-component workflow loading (Graph, Roles, Logic) |
| `MemoryMessageLog` | `R/message_log.R` | Non-persistent logging for rapid prototyping/debugging |
| `MemorySaver` | `R/checkpointer.R` | Transient checkpointing in RAM for testing |
| `mermaid_to_dag` | `R/dag.R` | Declarative DAG construction from Mermaid strings |
| `MessageLog` | `R/message_log.R` | Base class for all communication audit logging |
| `OllamaDriver` | `R/drivers_cli.R` | Local LLM execution via Ollama CLI |
| `OpenAIAPIDriver` | `R/drivers_api.R` | State-of-the-art API interaction with GPT-4 models |
| `OpenAICodexCLIDriver` | `R/drivers_cli.R` | Legacy CLI support for OpenAI Codex models |
| `RDSSaver` | `R/checkpointer.R` | File-based session persistence via RDS |
| `reducer_append` | `R/state.R` | Accumulating node outputs into state-level audit trails |
| `reducer_merge_list` | `R/state.R` | Seamless merging of parallel agent results into a dict |
| `register_logic` | `R/registry.R` | Secure registration of R functions for YAML reference |
| `register_role` | `R/registry.R` | Defining technical personas for parallel LLM agents |
| `render_workflow_file` | `R/validation.R` | Exporting high-res Mermaid diagrams for reports |
| `resolve_default_driver`| `R/factory.R` | Multi-tier resolution of drivers (Shorthand, ID, Registry) |
| `RestrictedState` | `R/state_restricted.R`| Secure inter-agent private messaging (True Privacy) |
| `set_default_driver` | `R/driver_registry.R` | Configuring the global package-wide LLM fallback |
| `spawn_dag` | `R/registry.R` | Full lifecycle instantiation from YAML to execution |
| `standard_node_factory`| `R/factory.R` | Mapping Mermaid labels to logic and LLM functions |
| `validate_workflow_file`| `R/validation.R` | Holistic YAML/Mermaid/R syntax validation gate |
| `validate_workflow_full`| `R/validation.R` | Deep topological audit of instantiated DAGs |

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-04-09 -->

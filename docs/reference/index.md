# Package index

## Core Orchestration

The heart of the HydraR framework.

- [`AgentDAG`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDAG.md)
  : Agent Graph R6 Class
- [`AgentNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentNode.md)
  : Agent Node Base Class
- [`AgentState`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentState.md)
  : Agent State R6 Class

## Agent Nodes

Specialized nodes for LLM interaction, logical routing, and scaling.

- [`AgentLLMNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentLLMNode.md)
  : Agent LLM Node R6 Class
- [`AgentLogicNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentLogicNode.md)
  : Agent Logic Node R6 Class
- [`AgentRouterNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentRouterNode.md)
  : Agent Router Node R6 Class
- [`AgentMapNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentMapNode.md)
  : Agent Map Node R6 Class
- [`AgentObserverNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentObserverNode.md)
  : Agent Observer Node R6 Class
- [`AgentBashNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentBashNode.md)
  : Bash Execution Node
- [`AgentPythonNode`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentPythonNode.md)
  : Python Execution Node
- [`add_llm_node()`](https://APAF-bioinformatics.github.io/HydraR/reference/add_llm_node.md)
  : Create an LLM Agent Node
- [`add_logic_node()`](https://APAF-bioinformatics.github.io/HydraR/reference/add_logic_node.md)
  : Create an R Logic Node
- [`dag_add_llm_node()`](https://APAF-bioinformatics.github.io/HydraR/reference/dag_add_llm_node.md)
  : Add an LLM Agent Node directly to a DAG
- [`dag_add_logic_node()`](https://APAF-bioinformatics.github.io/HydraR/reference/dag_add_logic_node.md)
  : Add an R Logic Node directly to a DAG
- [`standard_node_factory()`](https://APAF-bioinformatics.github.io/HydraR/reference/standard_node_factory.md)
  : Standard Node Factory for Mermaid
- [`auto_node_factory()`](https://APAF-bioinformatics.github.io/HydraR/reference/auto_node_factory.md)
  : Automatic Node Factory for Mermaid-as-Source

## Parallelism & Merge Harmonization

Infrastructure for isolated execution and conflict resolution.

- [`WorktreeManager`](https://APAF-bioinformatics.github.io/HydraR/reference/WorktreeManager.md)
  : Git Worktree Manager R6 Class
- [`ConflictResolver`](https://APAF-bioinformatics.github.io/HydraR/reference/ConflictResolver.md)
  : Git Conflict Resolver R6 Class
- [`create_merge_harmonizer()`](https://APAF-bioinformatics.github.io/HydraR/reference/create_merge_harmonizer.md)
  : Create a Merge Harmonizer Node
- [`RestrictedState`](https://APAF-bioinformatics.github.io/HydraR/reference/RestrictedState.md)
  : Restricted State R6 Class

## LLM Drivers

Provider-agnostic interfaces for CLI-based and API-based LLMs.

- [`AgentDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentDriver.md)
  : Agent Driver R6 Class
- [`GeminiCLIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/GeminiCLIDriver.md)
  : Gemini CLI Driver R6 Class
- [`GeminiAPIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/GeminiAPIDriver.md)
  : Gemini API Driver R6 Class
- [`GeminiImageDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/GeminiImageDriver.md)
  : Gemini Image API Driver R6 Class
- [`OpenAIAPIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/OpenAIAPIDriver.md)
  : OpenAI API Driver
- [`AnthropicAPIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AnthropicAPIDriver.md)
  : Anthropic API Driver
- [`OllamaDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/OllamaDriver.md)
  : Ollama Driver R6 Class
- [`AnthropicCLIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/AnthropicCLIDriver.md)
  : Anthropic CLI Driver
- [`CopilotCLIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/CopilotCLIDriver.md)
  : Copilot CLI Driver R6 Class
- [`OpenAICodexCLIDriver`](https://APAF-bioinformatics.github.io/HydraR/reference/OpenAICodexCLIDriver.md)
  : OpenAI Codex CLI Driver R6 Class

## Dynamic Registry & Workflow Lifecycle

Tools for hot-swapping drivers, registering domain-specific logic, and
spawning DAGs.

- [`DriverRegistry`](https://APAF-bioinformatics.github.io/HydraR/reference/DriverRegistry.md)
  : Driver Registry R6 Class
- [`get_driver_registry()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_driver_registry.md)
  : Global Driver Registry Accessor
- [`list_logic()`](https://APAF-bioinformatics.github.io/HydraR/reference/list_logic.md)
  : List Registered Components
- [`get_logic()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_logic.md)
  : Get Logic Function
- [`register_logic()`](https://APAF-bioinformatics.github.io/HydraR/reference/register_logic.md)
  : Register Logic Function
- [`get_agent_roles()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_agent_roles.md)
  : List Registered Roles
- [`get_role()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_role.md)
  : Get an LLM Role (System Prompt)
- [`register_role()`](https://APAF-bioinformatics.github.io/HydraR/reference/register_role.md)
  : Register an LLM Role (System Prompt)
- [`set_default_driver()`](https://APAF-bioinformatics.github.io/HydraR/reference/set_default_driver.md)
  : Set the Default Agent Driver
- [`get_default_driver()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_default_driver.md)
  : Get the Default Agent Driver
- [`get_role_prompt()`](https://APAF-bioinformatics.github.io/HydraR/reference/get_role_prompt.md)
  : Get a Role-specific System Prompt
- [`resolve_default_driver()`](https://APAF-bioinformatics.github.io/HydraR/reference/resolve_default_driver.md)
  : \<!– APAF Bioinformatics \| factory.R \| Approved \| 2026-03-30 –\>
  Resolve a Default Driver from Shorthand ID
- [`spawn_dag()`](https://APAF-bioinformatics.github.io/HydraR/reference/spawn_dag.md)
  : Spawn an AgentDAG from a Workflow Object
- [`load_workflow()`](https://APAF-bioinformatics.github.io/HydraR/reference/load_workflow.md)
  : Load Multi-Agent Workflow from File

## Messaging & Persistence

State persistence, inter-node messaging, and telemetry infrastructure.

- [`MessageLog`](https://APAF-bioinformatics.github.io/HydraR/reference/MessageLog.md)
  : Message Log Base R6 Class
- [`MemoryMessageLog`](https://APAF-bioinformatics.github.io/HydraR/reference/MemoryMessageLog.md)
  : Memory Message Log R6 Class
- [`DuckDBMessageLog`](https://APAF-bioinformatics.github.io/HydraR/reference/DuckDBMessageLog.md)
  : DuckDB Message Log R6 Class
- [`JSONLMessageLog`](https://APAF-bioinformatics.github.io/HydraR/reference/JSONLMessageLog.md)
  : JSONL Message Log R6 Class
- [`Checkpointer`](https://APAF-bioinformatics.github.io/HydraR/reference/Checkpointer.md)
  : Checkpointer Interface
- [`MemorySaver`](https://APAF-bioinformatics.github.io/HydraR/reference/MemorySaver.md)
  : MemorySaver Checkpointer
- [`DuckDBSaver`](https://APAF-bioinformatics.github.io/HydraR/reference/DuckDBSaver.md)
  : DuckDBSaver Checkpointer
- [`RDSSaver`](https://APAF-bioinformatics.github.io/HydraR/reference/RDSSaver.md)
  : RDS File Checkpointer
- [`init_bot_history()`](https://APAF-bioinformatics.github.io/HydraR/reference/init_bot_history.md)
  : Initialize Bot History DuckDB

## Utilities & Parsing

Helper functions for mermaid visualization, validation, and maintenance.

- [`AgentTool`](https://APAF-bioinformatics.github.io/HydraR/reference/AgentTool.md)
  : Agent Tool R6 Class
- [`dag_create()`](https://APAF-bioinformatics.github.io/HydraR/reference/dag_create.md)
  : Create an Agent Graph
- [`parse_mermaid()`](https://APAF-bioinformatics.github.io/HydraR/reference/parse_mermaid.md)
  : Parse Mermaid Flowchart Syntax
- [`mermaid_to_dag()`](https://APAF-bioinformatics.github.io/HydraR/reference/mermaid_to_dag.md)
  : Create AgentDAG from Mermaid
- [`extract_r_code_advanced()`](https://APAF-bioinformatics.github.io/HydraR/reference/extract_r_code_advanced.md)
  : Extract R Code from LLM Response
- [`is_named_list()`](https://APAF-bioinformatics.github.io/HydraR/reference/is_named_list.md)
  : Check if an object is a named list
- [`format_toolset()`](https://APAF-bioinformatics.github.io/HydraR/reference/format_toolset.md)
  : Format Toolset for Prompt
- [`reducer_merge_list()`](https://APAF-bioinformatics.github.io/HydraR/reference/reducer_merge_list.md)
  : Built-in Reducer: Merge List
- [`reducer_append()`](https://APAF-bioinformatics.github.io/HydraR/reference/reducer_append.md)
  : Built-in Reducer: Append
- [`validate_workflow_file()`](https://APAF-bioinformatics.github.io/HydraR/reference/validate_workflow_file.md)
  : Validate Workflow File Syntax and Consistency
- [`validate_workflow_full()`](https://APAF-bioinformatics.github.io/HydraR/reference/validate_workflow_full.md)
  : Validate HydraR Workflow Integration
- [`render_workflow_file()`](https://APAF-bioinformatics.github.io/HydraR/reference/render_workflow_file.md)
  : Render Workflow Diagram from File
- [`cleanup_jules_branches()`](https://APAF-bioinformatics.github.io/HydraR/reference/cleanup_jules_branches.md)
  : Cleanup Stale GitHub Branches

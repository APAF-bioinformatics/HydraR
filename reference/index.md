# Package index

## Core Orchestration

The heart of the HydraR framework.

- [`AgentDAG`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDAG.md)
  : Agent Graph R6 Class
- [`AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
  : Agent Node Base Class
- [`AgentState`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentState.md)
  : Agent State R6 Class

## Agent Nodes

Specialized nodes for LLM interaction, logical routing, and scaling.

- [`AgentLLMNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLLMNode.md)
  : Agent LLM Node R6 Class
- [`AgentLogicNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLogicNode.md)
  : Agent Logic Node R6 Class
- [`AgentRouterNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentRouterNode.md)
  : Agent Router Node R6 Class
- [`AgentMapNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentMapNode.md)
  : Agent Map Node R6 Class
- [`AgentObserverNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentObserverNode.md)
  : Agent Observer Node R6 Class
- [`AgentBashNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentBashNode.md)
  : Bash Execution Node
- [`AgentPythonNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentPythonNode.md)
  : Python Execution Node
- [`add_llm_node()`](https://github.com/APAF-bioinformatics/HydraR/reference/add_llm_node.md)
  : Create an LLM Agent Node easily
- [`add_logic_node()`](https://github.com/APAF-bioinformatics/HydraR/reference/add_logic_node.md)
  : Create an R Logic Node easily
- [`dag_add_llm_node()`](https://github.com/APAF-bioinformatics/HydraR/reference/dag_add_llm_node.md)
  : Add an LLM Agent Node directly to a DAG
- [`dag_add_logic_node()`](https://github.com/APAF-bioinformatics/HydraR/reference/dag_add_logic_node.md)
  : Add an R Logic Node directly to a DAG
- [`standard_node_factory()`](https://github.com/APAF-bioinformatics/HydraR/reference/standard_node_factory.md)
  : Standard Node Factory for Mermaid
- [`auto_node_factory()`](https://github.com/APAF-bioinformatics/HydraR/reference/auto_node_factory.md)
  : Automatic Node Factory for Mermaid-as-Source

## Parallelism & Merge Harmonization

Infrastructure for isolated execution and conflict resolution.

- [`WorktreeManager`](https://github.com/APAF-bioinformatics/HydraR/reference/WorktreeManager.md)
  : Git Worktree Manager R6 Class
- [`ConflictResolver`](https://github.com/APAF-bioinformatics/HydraR/reference/ConflictResolver.md)
  : Git Conflict Resolver R6 Class
- [`create_merge_harmonizer()`](https://github.com/APAF-bioinformatics/HydraR/reference/create_merge_harmonizer.md)
  : Create a Merge Harmonizer Node
- [`RestrictedState`](https://github.com/APAF-bioinformatics/HydraR/reference/RestrictedState.md)
  : Restricted State R6 Class

## LLM Drivers

Provider-agnostic interfaces for CLI-based and API-based LLMs.

- [`AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
  : Agent Driver R6 Class
- [`GeminiCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiCLIDriver.md)
  : Gemini CLI Driver R6 Class
- [`GeminiAPIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiAPIDriver.md)
  : Gemini API Driver R6 Class
- [`GeminiImageDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiImageDriver.md)
  : Gemini Image API Driver R6 Class
- [`OpenAIAPIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OpenAIAPIDriver.md)
  : OpenAI API Driver
- [`AnthropicAPIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AnthropicAPIDriver.md)
  : Anthropic API Driver
- [`OllamaDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OllamaDriver.md)
  : Ollama Driver R6 Class
- [`AnthropicCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AnthropicCLIDriver.md)
  : Anthropic CLI Driver
- [`CopilotCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/CopilotCLIDriver.md)
  : Copilot CLI Driver R6 Class
- [`OpenAICodexCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OpenAICodexCLIDriver.md)
  : OpenAI Codex CLI Driver R6 Class

## Dynamic Registry & Workflow Lifecycle

Tools for hot-swapping drivers, registering domain-specific logic, and
spawning DAGs.

- [`DriverRegistry`](https://github.com/APAF-bioinformatics/HydraR/reference/DriverRegistry.md)
  : Driver Registry R6 Class
- [`get_driver_registry()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_driver_registry.md)
  : Global Driver Registry Accessor
- [`list_logic()`](https://github.com/APAF-bioinformatics/HydraR/reference/list_logic.md)
  : List Registered Components
- [`get_logic()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_logic.md)
  : Get Logic Function
- [`register_logic()`](https://github.com/APAF-bioinformatics/HydraR/reference/register_logic.md)
  : Register Logic Function
- [`get_agent_roles()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_agent_roles.md)
  : List Registered Roles
- [`get_role()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_role.md)
  : Get an LLM Role (System Prompt)
- [`register_role()`](https://github.com/APAF-bioinformatics/HydraR/reference/register_role.md)
  : Register an LLM Role (System Prompt)
- [`set_default_driver()`](https://github.com/APAF-bioinformatics/HydraR/reference/set_default_driver.md)
  : Set the Default Agent Driver
- [`get_default_driver()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_default_driver.md)
  : Get the Default Agent Driver
- [`get_role_prompt()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_role_prompt.md)
  : Get a Role-specific System Prompt
- [`resolve_default_driver()`](https://github.com/APAF-bioinformatics/HydraR/reference/resolve_default_driver.md)
  : \<!– APAF Bioinformatics \| factory.R \| Approved \| 2026-03-30 –\>
  Resolve a Default Driver from Shorthand ID
- [`spawn_dag()`](https://github.com/APAF-bioinformatics/HydraR/reference/spawn_dag.md)
  : Spawn an AgentDAG from a Workflow Object
- [`load_workflow()`](https://github.com/APAF-bioinformatics/HydraR/reference/load_workflow.md)
  : Load Multi-Agent Workflow from File

## Messaging & Persistence

State persistence, inter-node messaging, and telemetry infrastructure.

- [`MessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MessageLog.md)
  : Message Log Base R6 Class
- [`MemoryMessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MemoryMessageLog.md)
  : Memory Message Log R6 Class
- [`DuckDBMessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/DuckDBMessageLog.md)
  : DuckDB Message Log R6 Class
- [`JSONLMessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/JSONLMessageLog.md)
  : JSONL Message Log R6 Class
- [`Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
  : Checkpointer Interface
- [`MemorySaver`](https://github.com/APAF-bioinformatics/HydraR/reference/MemorySaver.md)
  : MemorySaver Checkpointer
- [`DuckDBSaver`](https://github.com/APAF-bioinformatics/HydraR/reference/DuckDBSaver.md)
  : DuckDBSaver Checkpointer
- [`RDSSaver`](https://github.com/APAF-bioinformatics/HydraR/reference/RDSSaver.md)
  : RDS File Checkpointer
- [`init_bot_history()`](https://github.com/APAF-bioinformatics/HydraR/reference/init_bot_history.md)
  : Initialize Bot History DuckDB

## Utilities & Parsing

Helper functions for mermaid visualization, validation, and maintenance.

- [`AgentTool`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentTool.md)
  : Agent Tool R6 Class
- [`dag_create()`](https://github.com/APAF-bioinformatics/HydraR/reference/dag_create.md)
  : Create an Agent Graph
- [`parse_mermaid()`](https://github.com/APAF-bioinformatics/HydraR/reference/parse_mermaid.md)
  : Parse Mermaid Flowchart Syntax
- [`mermaid_to_dag()`](https://github.com/APAF-bioinformatics/HydraR/reference/mermaid_to_dag.md)
  : Create AgentDAG from Mermaid
- [`extract_r_code_advanced()`](https://github.com/APAF-bioinformatics/HydraR/reference/extract_r_code_advanced.md)
  : Extract R Code from LLM Response
- [`is_named_list()`](https://github.com/APAF-bioinformatics/HydraR/reference/is_named_list.md)
  : Check if an object is a named list
- [`format_toolset()`](https://github.com/APAF-bioinformatics/HydraR/reference/format_toolset.md)
  : Format Toolset for Prompt
- [`reducer_merge_list()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_merge_list.md)
  : Built-in Reducer: Merge List
- [`reducer_append()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_append.md)
  : Built-in Reducer: Append
- [`validate_workflow_file()`](https://github.com/APAF-bioinformatics/HydraR/reference/validate_workflow_file.md)
  : Validate Workflow File Syntax and Consistency
- [`validate_workflow_full()`](https://github.com/APAF-bioinformatics/HydraR/reference/validate_workflow_full.md)
  : Validate HydraR Workflow Integration
- [`render_workflow_file()`](https://github.com/APAF-bioinformatics/HydraR/reference/render_workflow_file.md)
  : Render Workflow Diagram from File
- [`cleanup_jules_branches()`](https://github.com/APAF-bioinformatics/HydraR/reference/cleanup_jules_branches.md)
  : Cleanup Stale GitHub Branches

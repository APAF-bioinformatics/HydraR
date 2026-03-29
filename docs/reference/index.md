# Package index

## Core Orchestration

The heart of the HydraR framework.

- [`AgentDAG`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDAG.md)
  : Agent Graph R6 Class
- [`AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
  : Agent Node R6 Class
- [`AgentState`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentState.md)
  : Agent State R6 Class

## Agent Nodes

Specialized nodes for LLM interaction and logical routing.

- [`AgentLLMNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLLMNode.md)
  : Agent LLM Node R6 Class
- [`AgentLogicNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLogicNode.md)
  : Agent Logic Node R6 Class
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
- [`OpenAIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OpenAIDriver.md)
  : OpenAI API Driver R6 Class
- [`AnthropicDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AnthropicDriver.md)
  : Anthropic API Driver R6 Class
- [`OllamaDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OllamaDriver.md)
  : Ollama Driver R6 Class
- [`ClaudeCodeDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/ClaudeCodeDriver.md)
  : Claude CLI Driver R6 Class
- [`CopilotCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/CopilotCLIDriver.md)
  : Copilot CLI Driver R6 Class

## Dynamic Driver & Logic Registry

Tools for hot-swapping drivers and registering domain-specific logic.

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

## Messaging & Persistence

State persistence and inter-node messaging infrastructure.

- [`MessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MessageLog.md)
  : Message Log Base R6 Class
- [`MemoryMessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MemoryMessageLog.md)
  : Memory Message Log R6 Class
- [`DuckDBMessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/DuckDBMessageLog.md)
  : DuckDB Message Log R6 Class
- [`Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
  : Checkpointer Interface
- [`MemorySaver`](https://github.com/APAF-bioinformatics/HydraR/reference/MemorySaver.md)
  : MemorySaver Checkpointer
- [`DuckDBSaver`](https://github.com/APAF-bioinformatics/HydraR/reference/DuckDBSaver.md)
  : DuckDBSaver Checkpointer
- [`RDSSaver`](https://github.com/APAF-bioinformatics/HydraR/reference/RDSSaver.md)
  : RDS File Checkpointer

## Utilities & Parsing

Helper functions for mermaid visualization and code extraction.

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
- [`format_toolset()`](https://github.com/APAF-bioinformatics/HydraR/reference/format_toolset.md)
  : Format Toolset for Prompt
- [`reducer_merge_list()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_merge_list.md)
  : Built-in Reducer: Merge List
- [`reducer_append()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_append.md)
  : Built-in Reducer: Append

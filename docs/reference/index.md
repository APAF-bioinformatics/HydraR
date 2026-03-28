# Package index

## Core Orchestration

The heart of the HydraR framework.

- [`AgentDAG`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDAG.md)
  : Agent Graph R6 Class
- [`AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
  : Agent Node R6 Class
- [`AgentState`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentState.md)
  : Agent State R6 Class
- [`Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
  : Checkpointer Interface
- [`MemorySaver`](https://github.com/APAF-bioinformatics/HydraR/reference/MemorySaver.md)
  : MemorySaver Checkpointer
- [`DuckDBSaver`](https://github.com/APAF-bioinformatics/HydraR/reference/DuckDBSaver.md)
  : DuckDBSaver Checkpointer

## Agent Nodes

Specialized nodes for LLM interaction and logical routing.

- [`AgentLLMNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLLMNode.md)
  : Agent LLM Node R6 Class
- [`AgentLogicNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentLogicNode.md)
  : Agent Logic Node R6 Class
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

## LLM Drivers

Provider-agnostic interfaces for CLI-based and API-based LLMs.

- [`AgentDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentDriver.md)
  : Agent Driver R6 Class
- [`GeminiCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/GeminiCLIDriver.md)
  : Gemini CLI Driver R6 Class
- [`OllamaDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/OllamaDriver.md)
  : Ollama Driver R6 Class
- [`ClaudeCodeDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/ClaudeCodeDriver.md)
  : Claude CLI Driver R6 Class
- [`CopilotCLIDriver`](https://github.com/APAF-bioinformatics/HydraR/reference/CopilotCLIDriver.md)
  : Copilot CLI Driver R6 Class

## Utilities & Parsing

Helper functions for mermaid visualization and code extraction.

- [`AgentTool`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentTool.md)
  : Agent Tool R6 Class
- [`parse_mermaid()`](https://github.com/APAF-bioinformatics/HydraR/reference/parse_mermaid.md)
  : Parse Mermaid Flowchart Syntax
- [`extract_r_code_advanced()`](https://github.com/APAF-bioinformatics/HydraR/reference/extract_r_code_advanced.md)
  : Extract R Code from LLM Response
- [`format_toolset()`](https://github.com/APAF-bioinformatics/HydraR/reference/format_toolset.md)
  : Format Toolset for Prompt
- [`reducer_merge_list()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_merge_list.md)
  : Built-in Reducer: Merge List
- [`reducer_append()`](https://github.com/APAF-bioinformatics/HydraR/reference/reducer_append.md)
  : Built-in Reducer: Append

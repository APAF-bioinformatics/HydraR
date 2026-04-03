# AgentDAG Roadmap & To-Do List

This document translates the state-of-the-art gap analysis from `notes/agent_dag_assessment.md` into actionable development steps. Note: The foundational centralized state management (using the `AgentState` R6 class) has already been implemented.

## 1. Advanced State Management (Reducers)
- [x] **Implement Complex Reducers**: Extend the `AgentState` initialization to support sophisticated reducer functions beyond simple variable replacement.
    - *Example*: A reducer that appends new conversational messages to an existing list (e.g., maintaining a full chat history for the LLM).
    - *Action*: Create default reducer functions in `R/agent_state.R` (e.g., `reducer_append`, `reducer_merge_list`).
- [x] **State Schema Validation**: Add optional strict typing or schema validation to `AgentState` to prevent malformed data from crashing the DAG.

## 2. Checkpointing and Persistence (High Priority)
- [x] **Design `Checkpointer` Interface**: Create an R6 class or system for saving the `AgentState` after *every* node execution.
    - *Action*: Implement `MemorySaver` (in-memory) and `DuckDBSaver` (integrating with `R/init_duckdb.R`).
- [x] **Implement "Time Travel"**: Allow the DAG to be initialized with a specific `thread_id` and resume execution from the exact state of a previous failure or pause point.
- [x] **Human-in-the-Loop (HITL) Pausing**: Introduce a mechanism to pause DAG execution at specific nodes, wait for external input/approval, and resume using the checkpoint.

## 3. Advanced Observability & Visualization
- [x] **Rich Visualization**: Upgrade the current `plot()` method.
    - *Action*: Export the graph structure to Mermaid.js syntax for interactive web rendering or markdown embedding.
- [x] **Deep Tracing Export**: Enhance `save_trace()` to be fully compatible with external observability tools (like a lightweight local viewer or standard JSON formats used by tools like LangSmith/OpenTelemetry).
- [x] **Node-Level Error Context**: Ensure stack traces from failed R logic nodes are embedded deeply into the telemetry logs.

## 4. API Usability
- [x] **Streamlined Node Creation**: Create helper functions or syntactic sugar for quickly adding standard LLM and Logic nodes to the DAG without verbose R6 instantiations.
- [x] **Validation Enhancements**: Expand the `compile()` step to detect unreachable nodes or potential infinite loops (beyond basic `max_steps` warnings).

## 5. Decoupling & Standalone Migration (HydraR)

### 5.1 Core Orchestration Extraction
- [x] **Initialize Standalone Package**: Create the `HydraR` R package skeleton.
- [x] **Migrate Core Components**: Move the following from `RforRobot` to the new package:
    - [x] `AgentDAG`: Graph state machine and execution logic.
    - [x] `AgentState`: Persistent data store.
    - [x] `Checkpointer`: SQLite/DuckDB-backed persistence.
    - [x] `AgentNode`: Base class for execution units.

### 5.2 Provider Driver Framework
- [x] **Implement `AgentDriver` Interface**: Create the abstract R6 base class for CLI-based LLM drivers.
    - [x] *Requirements*: System preparation (temp files), retry logic/backoff, output cleaning.
- [x] **Dynamic Tool/Skill Injection**: Implement a mechanism to inject relevant skills, agents, or command definitions into the CLI instance prompt or environment.
    - [x] *Goal*: Enable CLI-native tool calling or prompt-based tool discovery for different providers.
- [x] **Develop Core Drivers**:
    - [x] `GeminiCLIDriver`: Integration with the `gemini` CLI.
    - [x] `ClaudeCodeDriver`: Integration with the `claude` (Anthropic) CLI.
    - [x] `CopilotCLIDriver`: Integration with the GitHub Copilot CLI (`gh copilot`).
    - [x] `OllamaDriver`: Integration with local `ollama` CLI.

### 5.3 Integration & Cleanup
- [x] **Update `RforRobot` Dependencies**: Configure `RforRobot` to import and depend on the new library.
- [x] **Refactor `RforRobot` Nodes**: Register bioinformatic and refactoring-specific "Logic Nodes" within the new framework.
- [x] **Documentation & Examples**: Create "Hello World" agentic loop examples for the new library.

### 5.4 Distribution
- [x] **GitHub Publication**: Prepare the repository for public release.
- [x] **APAF Standardization**: Ensure all artifacts and templates follow the APAF Bioinformatics standards.

## 6. Mermaid-to-DAG Compilation (Experimental)

### 6.1 Mermaid Parser
- [x] **Regex Flowchart Parser**: Implement a parser that extracts nodes and directed edges from `graph TD` and `flowchart TD` strings.
- [x] **Metadata Mapping**: Establish a convention (e.g., node labels) to map Mermaid IDs to R functions or CLI tools.
    - [x] *Example*: `A[run_blast] --> B[parse_xml]`

### 6.2 Agentic Compiler
- [x] **`from_mermaid()` Method**: Create a high-level constructor that takes a Mermaid string and returns a compiled `AgentDAG` object.
- [x] **Validation Engine**: Detect circular dependencies or undefined "Actions" within the Mermaid source.
- [x] **Round-Trip Visualization**: Ensure any `compile()`d DAG can be exported *back* to Mermaid for verification.

## 7. Comprehensive Feature Testing
- [ ] **Tutorial Vignettes**: Create comprehensive, executable tutorials inspired by ADK (e.g., Story Teller, Travel Booking, Software Bug Assistant, Personalized Shopping, Academic Research, Data Science, Blog Writer).
- [ ] **DuckDB Restart Reprex Vignette**: Add a simple vignette example that tests restart functionality using DuckDB. Should demonstrate a reprex where code is fixed and execution restarted, fitting within JOSS word limits.
- [ ] **Integration Testing**: Add `testthat` coverage mirroring the vignette workflows to ensure robust DAG operations.

<!-- APAF Bioinformatics | agent_dag_todo.md | Pending Roadmap -->

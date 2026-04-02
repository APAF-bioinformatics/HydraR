# HydraR Mermaid Orchestration Cheatsheet

This document defines the reserved keywords and syntax for orchestrating HydraR agent networks directly within Mermaid diagrams.

## Reserved Keywords

To ensure consistent behavior across nodes and drivers, the following keys are reserved when used in the `ID["Label | key=value"]` syntax.

### 1. Node Configuration (`AgentNode`)
| Keyword | Type | Description |
| :--- | :--- | :--- |
| `retries` | Integer | Number of execution attempts on failure. |
| `timeout` | Integer | Maximum execution time in seconds. |
| `isolation` | Boolean | If `true`, runs in an isolated git worktree. |
| `priority` | Integer | Execution priority for parallel branches (higher = sooner). |
| `checkpoint` | Boolean | If `false`, disables state persistence for this node. |
| `type` | String | Node specialty: `logic` (default), `router`, `map`, `observer`. |
| `logic_id` | String | ID of the logic/function registered in `HydraR`. |
| `map_key` | String | (For `type=map`) The state key containing the list to map over. |
| `agents_files` | List | Comma-separated paths to markdown files for AI persona injection. |
| `skills_files` | List | Comma-separated paths to markdown files for AI capability injection. |

### 2. LLM / Driver Parameters (`AgentLLMNode`)
| Keyword | Type | Description |
| :--- | :--- | :--- |
| `model` | String | LLM model identifier (e.g., `gemini-2.5-flash`). |
| `role` | String | System prompt or persona (e.g., `Expert Researcher`). |
| `temp` | Float | Temperature (0.0 to 2.0). |
| `max_tokens`| Integer | Maximum response length. |
| `format` | String | Expected output format (`text`, `json`, `markdown`). |

### 3. CLI Driver Flags (Driver-Specific)
| Keyword | Type | Driver | Description |
| :--- | :--- | :--- | :--- |
| `sandbox` | Boolean | Gemini | Enable/disable sandbox execution. |
| `yolo` | Boolean | Gemini | Skip safety/confirmation checks. |
| `num_ctx` | Integer | Ollama | Context window size. |
| `verbose` | Boolean | Claude | Enable verbose CLI logging. |
| `aspect_ratio` | String | Gemini/OpenAI | Image dimensions (e.g., `1:1`, `16:9`). |
| `image_size` | String | Gemini/OpenAI | Output resolution (e.g., `1K`, `2K`, `512`). |
| `output_dir` | String | Logic/Driver | Path to save generated binary assets. |

---

## Mermaid Orchestration Syntax

### Node Definition
```mermaid
graph TD
  ID["Human Label | key1=val1 | key2=val2"]
```

### Directives & Types
| Syntax | Interpretation | Example |
| :--- | :--- | :--- |
| `key=3` | Numeric | `retries=3` |
| `key=true` | Logical | `isolation=true` |
| `key=null` | NULL | `model=null` |
| `key=NA` | NA | `temp=NA` |
| `key=val` | String | `role=Analyst` |

### Multi-Line Definitions
For complex nodes, define the label and parameters in the first occurrence; subsequent occurrences can use just the ID.
```mermaid
graph TD
  A["Researcher | model=gemini-1.5-pro | isolation=true"]
  A --> B
  C --> A
```

### 5. Plotting & Visualization (API vs CLI)
When rendering the DAG via `dag$plot()`, the driver selection impacts the visual output:

*   **Labels**: If you call `dag$plot(details = TRUE)`, the generated Mermaid code will include the driver ID inside the node box. For example:
    *   **API**: `Planner["Travel Planner | type=llm | driver=gemini_api | model=..."]`
    *   **CLI**: `Planner["Travel Planner | type=llm | driver=gemini | model=..."]`
*   **Factory Logic**: The `auto_node_factory()` uses the `driver` parameter to decide which R6 class to instantiate. `gemini` defaults to the CLI driver (via `GeminiCLIDriver`), while `gemini_api` and `gemini_image` route to the API-based drivers.
*   **Visual Styling**: Currently, both use the same CSS classes (e.g., green for success), but the text label is the primary way to tell them apart when viewing the graph structure.

---

## Orchestration Patterns

### 1. Parallel Isolation
Use `isolation=true` to trigger parallel git worktree branches.
```mermaid
graph TD
  Start --> BranchA["Task A | isolation=true"]
  Start --> BranchB["Task B | isolation=true"]
  BranchA --> Merge
  BranchB --> Merge
```

### 2. Conditional Routing & Dynamic Mapping
Edge labels like `Test` (success) and `Fail` (failure) can be used for built-in conditional logic.

```mermaid
graph TD
  M["List Processor | type=map | map_key=items | logic_id=process_fn"]
  R["Router | type=router | logic_id=voter_logic"]
  R --> NodeA
  R --> NodeB
```

### 3. Resilient Failover (Error Edges)
Standard edges represent the happy path. Error edges define the failover path if a node fails.

| Syntax | Interpretation | Visual |
| :--- | :--- | :--- |
| `A --> B` | Standard Transition | Green/Solid |
| `A -- "Test" --> B` | Success Path (Conditional) | Green/Solid |
| `A -- "Fail" --> C` | Failure Path (Conditional) | Yellow/Solid |
| `A -- "error" --> D` | Failover / Error Path | Red/Dashed |

```mermaid
graph TD
  Check["Verify | type=logic | logic_id=check_val"]
  Check -- "Test" --> Success
  Check -- "Fail" --> Retry
  Check -- "error" --> Halt["Emergency Stop"]
```

### 4. Multimodal Image Generation
Use `driver=gemini_image` or `openai_image` for generating binary visual assets.
```mermaid
graph TD
  IG["Image Generator | driver=gemini_image | model=gemini-3.1-flash-image-preview | aspect_ratio=16:9 | output_dir=vignettes/images"]
```

### 5. Context & System Prompt Injection
HydraR automatically manages the "Rules of the House" for LLM nodes by injecting markdown files into the `system_prompt`.

*   **Automatic Worktree Injection**: Every `AgentLLMNode` automatically detects and injects `agents.md` and `skills.md` if they exist in the active worktree (sandbox).
*   **Static File Injection**: Use `agents_files` and `skills_files` to inject specific instructions across multiple files.
*   **Mermaid Syntax**: Use comma-separated strings for multiple files.

```mermaid
graph TD
  A["Researcher | type=llm | agents_files=global_rules.md,local_rules.md | skills_files=bash_skills.md"]
```

> [!TIP]
> This pattern allows you to keep your Mermaid diagrams clean while still enforcing complex project standards across all agents.

> [!IMPORTANT]
> **Deduplication**: If a node is defined multiple times with different parameters, HydraR prioritizes the **first** definition containing a pipe `|`.
> **Case Sensitivity**: Reserved keywords are case-sensitive and should be lowercase. values like `true`/`false` are case-insensitive.

<!-- APAF Bioinformatics | HydraR | Approved | 2026-04-03 -->


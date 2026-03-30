# Declarative Workflow Loader — Implementation Notes (2026-03-30)
<!-- APAF Bioinformatics | Macquarie University | APAF-Agentic-Standard -->

## Objective
Modernize the HydraR framework by implementing a "Declarative Workflow" system that enables users to define complex multi-agent workflows entirely through YAML/JSON and Mermaid syntax, achieving a **Zero-R-Code** definition goal.

## Key Components

### 1. Unified Loader: `load_workflow(path)`
A single entry point for ingesting complete workflow definitions. It populates roles and logic registries, extracts initial state, and returns the Mermaid graph string.

### 2. 3-Tier Logic Resolution Strategy
HydraR acts as an interpreter for a language-independent manifest using a hierarchical resolution logic:
1.  **Tier 1 (File)**: If the logic value is a string, ends in `.R` and exists on disk, it is `source()`-ed.
2.  **Tier 2 (Function)**: If it matches an existing R function name (checked via `exists(v, mode="function")`), the function is retrieved.
3.  **Tier 3 (Code Snippet)**: If neither of the above, it is treated as a raw R code block and automatically wrapped in `function(state) { ... }`, with full access to the `state` object.

### 3. Declarative Mermaid Nodes
Mermaid node labels now support `type=llm|logic|merge` annotations. The `auto_node_factory()` universal factory resolves these annotations at graph creation time using the registries populated by `load_workflow()`.

## Implementation Details

### Files Modified:
-   **`R/registry.R`**: Core implementation of `load_workflow()`, `resolve_logic_pattern()`, and role registration.
-   **`R/factory.R`**: Implementation of `auto_node_factory()` and `resolve_default_driver()` to handle declarative Mermaid parameters.
-   **`DESCRIPTION`**: Added `yaml` dependency to support `.yml` and `.yaml` formats.

### Verification:
-   **Tests**: 49 tests for `auto_node_factory` and 14 tests for `load_workflow` (266 total tests passing).
-   **Vignettes**: Both `sorting_benchmark.Rmd` and `hong_kong_travel.Rmd` refactored to use the Zero-R-Code pattern.

### R Partial-Matching Bug Fix:
During implementation, a classic R "gotcha" was identified and patched. `params$role` was found to partially match `params$role_id` via R's `$` operator. All parameter lookups in the factory have been updated to use `params[["key"]]` for exact matching.

## Future Vision
The YAML/Mermaid manifest represents an **APAF-Agentic-Standard** that can theoretically be implemented in other languages (Python, Julia), with HydraR serving as the reference R-native interpreter.

## YAML Syntax Note: Block Scalars

When defining workflows in YAML, two types of block scalars are used to manage multi-line strings:

### 1. Literal Block Scalar (`|`)
- **Key usage**: `graph:`
- **Behavior**: Preserves all newlines and indentation exactly as typed.
- **Why**: Mermaid syntax is **line-sensitive**. Each node/edge must be on its own line for the parser to build the DAG correctly.

### 2. Folded Block Scalar (`>`)
- **Key usage**: `roles:` (LLM system prompts)
- **Behavior**: Replaces single newlines with spaces (folds the block), but preserves double newlines (paragraphs).
- **Why**: LLM prompts are typically long continuous strings. Using `>` allows the prompt to be formatted across multiple lines in the YAML file for readability without injecting actual line breaks into the agent's system prompt.

## The Tab Taboo: Tab-Zero Tolerance

A critical "gotcha" in the **APAF-Agentic-Standard**:

> [!WARNING]
> **TAB characters are strictly forbidden for indentation in YAML.**

- **YAML Parser**: `yaml::read_yaml()` will throw a syntax error immediately if an actual Tab (`	`) is used for indentation.
- **Workflow Consistency**: Even inside literal blocks (`|`), Tabs are **strongly discouraged**. Because HydraR acts as a cross-platform interpreter, using Spaces (usually 2 or 4) ensures the R `parse()` function, Python interpreters, and Mermaid renderers all see the exact same layout.

---
<!-- APAF Bioinformatics | workflow_loader_notes_20260330.md | Approved | 2026-03-30 -->

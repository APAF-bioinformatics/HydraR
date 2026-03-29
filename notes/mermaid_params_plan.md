# Implementation Plan - Bidirectional Mermaid Parameters

This plan implements the "Parameter Round-trip" system for HydraR, allowing users to define node configuration (retries, work directories, etc.) directly in Mermaid syntax and visualize them back from R.

## Proposed Changes

### Core Orchestration

#### [MODIFY] [node.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/node.R)
- Add a `params` field to the `AgentNode` R6 class.
- Update `initialize(id, label, params)` to store these values.

#### [MODIFY] [mermaid_parser.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/mermaid_parser.R)
- Update `parse_mermaid` to split labels by the pipe `|` delimiter.
- Extract `key=value` pairs into a named list.
- Automatically coerce numeric and logical strings (e.g., `retries=3` becomes numeric `3`).
- Support edge cases like spaces around `=`, slashes in paths, and brackets in values.

#### [MODIFY] [dag.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/dag.R)
- **`plot()` Enhancement**: 
    - Add `details` (logical), `include_params` (filter list), and `show_edge_labels` (logical, default `TRUE`) arguments.
    - If `details=TRUE`, serialize `node$params` using the `|` syntax, filtering by `include_params`.
    - Support toggling edge labels globally.
- **`from_mermaid()` Enhancement**: 
    - Extract params from the parser and pass them to the `node_factory`. 
    - Handle both 2-argument and 3-argument factory signatures for backward compatibility.

### Verification & Examples

#### [NEW] [test-mermaid_params.R](file:///Users/ignatiuspang/Workings/2026/HydraR/tests/testthat/test-mermaid_params.R)
- Verify extraction of strings, numbers, and booleans.
- Test edge cases: special characters in paths, spaces around `=`, and brackets in values.
- Verify the round-trip: `Mermaid -> DAG -> plot(details=TRUE)`.

#### [NEW] [parameterized_mermaid.R](file:///Users/ignatiuspang/Workings/2026/HydraR/examples/parameterized_mermaid.R)
- A practical demo showing how to use `retries` and `workdir` parameters defined directly in a Mermaid string.

---

## User Review Required

> [!IMPORTANT]
> **Syntax choice**: Using `ID["Label | key=value"]` as it is valid Mermaid and easy to type.
> **Filtering**: Added a filter list to `plot()` to prevent cluttering the visualization with internal metadata.
> **Edge Labels**: Displayed by default, but can be disabled via `show_edge_labels = FALSE`.

<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-29 -->

# HydraR Technical Recommendations Report (2026-03-29)

This document outlines critical bugs, defensive programming enhancements, and architectural improvements identified during the comprehensive repository review.

## 🔴 Critical Bugs & Errors

### 1. Persistence Layer Failure (DuckDBSaver)
*   **Problem**: `DuckDBSaver` uses `jsonlite::toJSON` for state serialization. R functions (used in `reducers` and `schema` validation) cannot be natively serialized to JSON without losing their environment, closure, and body.
*   **Evidence**: `DuckDBSaver$get` reconstructs the `AgentState` using only `initial_data = state_data$data`, effectively discarding all `reducers` and `schema` logic.
*   **Impact**: Resuming a DAG from a DuckDB checkpoint will result in a state object that lacks custom merging logic (e.g., chat history appending) and type safety.
*   **Recommendation**:
    *   Switch to `base::serialize()` and `base::unserialize()` to store the entire `AgentState` object (or its internal environment) as a BLOB in DuckDB.
    *   Alternatively, implement a "Registry" pattern where reducers are referenced by name (strings) and looked up in a global registry during restoration.

### 2. Incomplete Graph Analysis in `compile()`
*   **Problem**: `AgentDAG$.rebuild_graph` only processes `self$edges`. It does not incorporate transitions defined in `self$conditional_edges`.
*   **Evidence**: The `igraph` object used for cycle detection and reachability checks is missing all "loop" and "conditional" paths.
*   **Impact**: `compile()` will fail to detect infinite loops or unreachable nodes that are part of conditional logic, leading to runtime hangs or unexpected "node not found" errors.
*   **Recommendation**: Update `.rebuild_graph` to iterate through `self$conditional_edges` and add edges to the `igraph` object for both `if_true` and `if_false` targets.

### 3. Brittle R Code Extraction
*   **Problem**: `extract_r_code_advanced` in `R/utils.R` only extracts the *first* detected code block.
*   **Evidence**: `matches[1]` is hardcoded in the return statement.
*   **Impact**: LLM responses containing multiple logical steps in separate blocks (e.g., `setup` then `analysis`) will be truncated, causing execution failures in downstream Logic Nodes.
*   **Recommendation**: Refactor to concatenate all detected blocks with a newline separator or return a list of blocks for sequential execution.

---

## 🛡️ Defensive Programming Enhancements

### 1. Replace Recursion with Iterative Queuing
*   **Issue**: `.run_linear` and `.run_iterative` use deep recursion (capped at 100).
*   **Risk**: While 100 is usually sufficient, R is not optimized for tail-call recursion. Large-scale scientific pipelines or high-frequency loops could hit the `expressions` limit or cause stack overflows.
*   **Recommendation**: Re-implement the execution engine using a `while(length(queue) > 0)` loop and a dynamic `step_count` tracker.

### 2. Hardened CLI Driver Status Checks
*   **Issue**: CLI drivers (Gemini, Ollama) call `system2` but do not consistently inspect the exit status.
*   **Risk**: If the CLI tool fails (e.g., "command not found", "connection refused", or "out of memory"), the error message is captured as `stdout` and returned as a "successful" response to the DAG.
*   **Recommendation**: Implement a private `.safe_exec` method in the `AgentDriver` base class that checks `attr(res, "status")` and throws an R `stop()` if the exit code is non-zero.

### 3. "True Privacy" in RestrictedState
*   **Issue**: `RestrictedState$get_all()` hides all keys starting with `.__inbox__`.
*   **Risk**: A node cannot see its *own* inbox through `get_all()`, which is counter-intuitive for debugging or bulk processing of messages.
*   **Recommendation**: Update the regex to allow the node's own inbox while hiding all others: `!grepl("^\\.__inbox__", names) | grepl(own_inbox_pattern, names)`.

### 4. Atomic Git Operations
*   **Issue**: `MergeHarmonizer` and `WorktreeManager` perform git operations (checkout, merge) without verifying the current state.
*   **Recommendation**: Before merging, explicitly verify that the working directory is "clean" (`git status --porcelain`) to prevent uncommitted changes from being accidentally merged or lost.

---

## 📝 Code Style & Documentation

*   **Error Messaging**: Standardize on `stop(sprintf(...))` instead of `stopifnot()` to provide actionable feedback to users during pipeline failures.
*   **rOpenSci Readiness**: Add `@return` and `@examples` to all exported functions in `R/dag.R` and `R/factory.R`.
*   **APAF Compliance**: Ensure all new `.R` files carry the standard header and watermark.

---
<!-- APAF Bioinformatics | HydraR | recommendations_20260329.md | Approved | 2026-03-29 -->

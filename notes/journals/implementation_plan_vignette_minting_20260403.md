# Implementation Plan: Advanced Vignette Minting (2026-04-03)
<!-- APAF Bioinformatics | HydraR | Planning -->

## Objective
Finalize the HydraR documentation suite for JOSS/rOpenSci submission by "minting" three advanced, orthogonal vignettes from the historical `notes/` archive into the canonical `vignettes/` directory.

## Current Vignette Suite
- [x] **`hong_kong_travel.Rmd`**: Multimodal / Conditional Loops / HTML Output.
- [x] **`sorting_benchmark.Rmd`**: Parallelism / Git Worktree Isolation / Merging.

## Proposed New Vignettes

### 1. [x] `state_persistence.Rmd` (Refactored)
*   **Description**: Demonstrates automated checkpointing/resume using the DuckDB checkpointer.
*   **Action**: 
    1.  Delete existing `vignettes/duckdb_restart_reprex.Rmd` and `duckdb_restart_reprex.R`.
    2.  Mint a fresh version from `notes/vignettes/reprex_duckdb.Rmd`.
    3.  **Upgrade**: Use the modern `AgentDAG$from_mermaid` declarative pattern and highlight the `status = "pause"` user-interruption feature.

### 2. [x] `extending_hydrar.Rmd`
*   **Description**: Shows developers how to create custom LLM drivers using R6 classes.
*   **Action**: Mint from `notes/vignettes/creating_drivers.Rmd`.
*   **Focus**: Subclassing `AgentDriver`, Mocking for tests, and ensuring Worktree-safety (`exec_in_dir`).

### 3. [x] `targets_integration.Rmd`
*   **Description**: Bridges HydraR with the `targets` workflow ecosystem.
*   **Action**: Mint from `notes/vignettes/targets_integration.Rmd`.
*   **Focus**: Macro-orchestration (DAG-as-Target) and integrated resiliency.

## Execution Workflow

1.  **File Migration**:
    *   Move `.Rmd` files to `vignettes/`.
    *   Ensure any corresponding `.yml` files (like `reprex_duckdb.yml`) are also moved.
2.  **Audit & Refactor**:
    *   Convert all examples to use the **Mermaid-to-DAG** pattern (Zero-R-Code).
    *   Update titles and YAML metadata to follow standard package formatting.
3.  **Cleanup**:
    *   Purge all `*.R` and `*.html` artifacts from `vignettes/` to keep only source files.
4.  **Verification**:
    *   Run `devtools::build_vignettes()` to ensure a clean build for all 5 vignettes.

## Open Questions
- [x] Should we also include the `academic_research.Rmd` as a simpler sequential DAG example? (Recommendation: Post-submission task, as the current suite is already quite rich). I agree with you not now. Don't do it now. Leave it. 

---
<!-- APAF Bioinformatics | implementation_plan_vignette_minting_20260403.md | Approved | 2026-04-03 -->

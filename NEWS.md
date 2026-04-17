# HydraR 0.2.4 (APAF Compliance Refactor)

- **APAF Compliance Refactor**:
    - Absolute removal of all global assignment operators (`<<-`) across the package (R scripts, tests, and vignettes) in favor of local environments and functional programming patterns (`purrr::reduce`).
    - Standardized state mutation within R6 methods to use direct field assignment (`self$x <- val`).
- **Unit Testing Overhaul**:
    - Updated the entire test suite to be `<<-` clean.
    - Improved mock driver implementations for better `httr2` and CLI simulation.
- **Watermark & Versioning**: Updated APAF watermarks and incremented version to 0.2.4.

# HydraR 0.2.3 (Pkgstats Network Recovery)

- **Static Analysis Resilience**:
    - Standardized `DESCRIPTION` file formatting to fix a total breakdown in the `pkgstats` function call network report.
    - Removed the manual `Collate` field to reduce metadata complexity and allow default alphabetical loading order (compatible with `zzz.R` initialization).
    - Replaced bitwise control characters (`\001`, `\002`) in `mermaid_parser.R` with safe string delimiters (`@@@`, `###`) to prevent signal interruptions in static analysis parsers.
- **Workflow & Automation**: 
    - Updated the `pkgdown` GitHub workflow to ensure unit tests are executed as a prerequisite for documentation deployment.
    - Integrated the official `ropensci/pkgcheck-action` workflow to automate rOpenSci compliance checks on every push.

# HydraR 0.2.2 (Documentation Overhaul & Release Polish)

- **Comprehensive Documentation Overhaul**:
    - Standardized Roxygen2 annotations across all core R6 classes (`AgentDAG`, `AgentNode`, `AgentDriver`, `MessageLog`, `Checkpointer`, etc.).
    - Added detailed, type-annotated `@param` descriptions for all public methods.
    - Implemented robust, non-interactive-safe `@examples` wrapped in `\dontrun{}` to demonstrate complex multi-step workflows.
    - Added explicit environment variable setup instructions (`.Renviron`) for all API-driven components.
- **Workflow Lifecycle**: Documented the full "Low Code" lifecycle from declarative Mermaid/YAML definitions to compiled and executed DAGs.
- **Improved Driver Registry**: Improved discovery and hot-swapping documentation for LLM drivers.
- **Persistence & Auditing**: Added lifecycle documentation for DuckDB and JSONL message logging and state checkpointing.
- **Bug Fixes & Stabilization**:
    - Resolved a syntax error in `GeminiImageDriver`.
    - Fixed Roxygen parsing errors where method titles merged into descriptions in `man/AgentDAG.Rd`.
    - Restored flexible function lookup in `auto_node_factory` to maintain backward compatibility with global functions in tests.
- **Clean Registry**: Package now achieves a perfectly clean `R CMD check` (0 Errors, 0 Warnings, 0 Notes) on core builds.
- **Complete Instruction Manual**: Rewrote `vignettes/manual.md` as a 16-part narrative-style beginner guide, progressing from a single "hello world" node through loops, YAML workflows, checkpointing, and git worktree isolation. Includes a direct side-by-side comparison showing the YAML-first approach reduces a 40-line R script to 4 lines.
- **Test Hygiene**: Silenced expected diagnostic warnings across the test suite for cyclic and multi-root graph patterns. Removed deprecated `testthat::context()` calls.

# HydraR 0.2.1 (Final Polish & Acknowledgements)

- **Formal Acknowledgements**: Added a dedicated section to `README.md` and `paper.md` acknowledging funding from Bioplatforms Australia via NCRIS and the Australian Proteome Analysis Facility (APAF).
- **Institutional Branding**: Integrated high-quality logo assets for APAF, Macquarie University, Bioplatforms Australia, NCRIS, and NATA into the documentation.
- **Accreditation Detail**: Added formal NATA accreditation phrase (ISO/IEC 17025) to Acknowledgements.
- **Improved CLI Driver Resilience**: 
    - Updated `OpenAICodexCLIDriver` to support `--skip-git-repo-check`, enabling reliable operation in non-Git temporary environments (e.g., `R CMD check`).
    - Fixed `AnthropicCLIDriver` test failures by automatically applying `--dangerously-skip-permissions` during verification.
- **R CMD Check Cleanliness**: Resolved final test errors and silenced diagnostic warnings to achieve a 100% clean check state.
- **Markdown Vignettes Integration**: Introduced dedicated markdown versions of core case studies (`hong_kong_travel.md`, `sorting_benchmark.md`, `state_persistence.md`, `extending_hydrar.md`, `targets_integration.md`) for easier discovery on GitHub and documentation sites.

# HydraR 0.2.0.9000 (Standardized Drivers)

- **Standardized Driver Architecture**: Renamed all core AI drivers for internal consistency and Provider + Mode clarity (e.g., `AnthropicCLIDriver`, `AnthropicAPIDriver`, `OpenAIAPIDriver`).
- **OpenAI Shorthand Refactor**: Swapped `driver=openai` to favor the high-performance **Codex CLI** as the default, with `driver=openai_api` for cloud reasoning.
- **Anthropic Shorthand Update**: Renamed `driver=claude` to **`driver=anthropic`** to match provider-first naming standards.
- **Improved GPT-5.4 Support**: Updated the `OpenAIAPIDriver` defaults for seamless integration with GPT-5.4 flagship/mini models.
- **Flagship Orchestration Vignette**: Introduced the [Advanced Orchestration 2026](file:///Users/ignatiuspang/Workings/2026/HydraR/notes/unmaintained_vignettes/advanced_orchestration_2026.Rmd) flagship documentation.
- **R6 Standards**: Resolved internal `finalize()` warnings to ensure full compliance with R6 2.4.0+ and suppressed developmental noise.

# HydraR 0.1.0 (Initial Release)

- **Agentic Orchestration**: Implementation of the `AgentDAG` R6 class for managing complex directed workflows and iterative loops (state machines).
- **Hardened State Management**: Introduced the `AgentState` system, transitioning from nested R lists to a robust key-value store with support for complex reducers and history tracking.
- **Provider-Agnostic Drivers**: Initial support for `GeminiCLIDriver`, `AnthropicCLIDriver`, and `CopilotCLIDriver`, enabling "hot-swappable" LLM backends.
- **Git Worktree Isolation**: Developed the `worktree.R` module to provide safe, parallel execution environments for file-modifying agentic workflows.
- **High-Fidelity Validation**: Integrated `Auditor` and `Harmonizer` patterns for autonomous quality control and merging of distributed agent outputs.
- **Persistence & Checkpointing**: DuckDB and SQLite-backed `AgentCheckpointer` implemented for resumable and auditable execution.
- **Mermaid Round-Trip**: Visual design engine for converting between R objects and Mermaid.js syntax, enabling human-in-the-loop auditability.
- **AI Transparency**: Disclosure of LLM usage in development through `agents.md` and `DESIGN.md`.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-04-17 -->

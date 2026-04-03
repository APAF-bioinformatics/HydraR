# HydraR Publication Strategy

This plan outlines the steps to prepare and submit `HydraR` to R package repositories. Based on the current state of the package and your goals, we will evaluate the three main venues: **CRAN**, **rOpenSci**, and **Bioconductor**.

## Publication Options Comparison

| Repository | Primary Focus | Peer Review | Pros | Cons |
| :--- | :--- | :--- | :--- | :--- |
| **CRAN** | General R software | Automated technical checks only | Maximum reach; default for R users. | High maintenance; no quality review. |
| **rOpenSci** | Open Science / Research | Thorough human peer-review | Prestigious Quality Stamp; community support. | Long review cycle; focus on quality and reproducibility. |
| **Bioconductor** | Bioinformatics / Genomics | Bioinformatics-specific review | Gold standard for biology. | Not a fit for this general-purpose tool. |

## Approved Path: General-Purpose Orchestration

> [!IMPORTANT]
> **Decision Confirmed**: `HydraR` will be positioned as a **General Purpose AI Agent Framework**. We will prioritize **CRAN** for distribution and **rOpenSci** for peer-reviewed quality validation. Bioconductor is now out of scope for this initial release.

## Proposed Changes

### Phase 1: Technical Hardening (CRAN Readiness)

We must first resolve the existing `R CMD check` notes to ensure the package passes the technical bar.

#### [MODIFY] [DESCRIPTION](file:///Users/ignatiuspang/Workings/2026/HydraR/DESCRIPTION)
-   Replace `Author` and `Maintainer` fields with a comprehensive `Authors@R` field.
-   Update `Depends` to `R (>= 4.1.0)` to explicitly handle the native pipe usage.
-   Refine the `Description` to emphasize reproducibility and scientific utility.

#### [MODIFY] [LICENSE](file:///Users/ignatiuspang/Workings/2026/HydraR/LICENSE)
-   Ensure the `LICENSE` file format matches CRAN's expectations for LGPL-3.

### Phase 2: Documentation & Positioning

#### [MODIFY] [README.md](file:///Users/ignatiuspang/Workings/2026/HydraR/README.md)
-   Add a **Scientific Use-Case** section demonstrating how `HydraR` enables reproducible bioinformatic analysis via agents.
-   Add a **Publication/Citation** placeholder.

#### [NEW] [rOpenSci_Submission.md](file:///Users/ignatiuspang/Workings/2026/HydraR/rOpenSci_Submission.md)
-   Draft the submission text for rOpenSci's software peer review process.

### Phase 3: Submission Execution

1.  **rOpenSci Onboarding**: Submit the package to the `ropensci/software-review` repository.
2.  **CRAN Submission**: Use `devtools::submit_cran()` after rOpenSci review (or in parallel if desired).
3.  **Bioconductor (Optional)**: If rOpenSci review suggests it, we can port to Bioconductor by adding Bio-specific examples.

## Open Questions

-   **Target Audience**: Do you want `HydraR` to be viewed as a general-purpose AI agent framework or specifically as a "Bioinformatics Agentic Framework"? (This decides the Bioconductor/rOpenSci positioning).
-   **License Preference**: LGPL-3 is currently specified. This is acceptable for CRAN but we should double-check if you'd prefer MIT or Apache 2.0 for a 'General Purpose' framework.

## Verification Plan

### Automated Tests
-   `rcmdcheck::rcmdcheck(args = "--as-cran")`: Must return 0 Errors, 0 Warnings, 0 Notes.
-   `devtools::check_win_devel()`: Verify on Windows build servers.
-   `urlchecker::url_check()`: Ensure all links in documentation are valid.

### Manual Verification
-   Verify all vignettes render correctly without interactive LLM calls (mock the drivers for CRAN checks).
-   Peer-review of the README for clarity and impact.

---
<!-- APAF Bioinformatics | publication_plan_20260329.md | Approved | 2026-03-29 -->

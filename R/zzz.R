# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        zzz.R
# Author:      APAF Agentic Workflow
# Purpose:     Package Initialization
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

.onLoad <- function(libname, pkgname) {
  # Register built-in reducers
  # Note: These functions are available in the package namespace
  register_logic("reducer_append", reducer_append)
  register_logic("reducer_merge_list", reducer_merge_list)

  # Flagship 2026 Roles
  register_role("research_planner", "You are a Senior Bioinformatics Planner at APAF. Decompose complex research requests into a sequence of R specific tasks.")
  register_role("apaf_coder", "You are a HydraR Engineering Agent. Implement efficient, vectorized R code (no for-loops) according to APAF Global standards.")
  register_role("apaf_auditor", "You are a Compliance Auditor. Review the preceding R code for APAF style, efficiency, and security leaks.")

  invisible(NULL)
}

# Note: Global variable bindings for R CMD check are managed in factory.R.

# <!-- APAF Bioinformatics | zzz.R | Approved | 2026-03-31 -->

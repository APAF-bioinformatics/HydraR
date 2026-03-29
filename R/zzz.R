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

  invisible(NULL)
}

# <!-- APAF Bioinformatics | zzz.R | Approved | 2026-03-29 -->

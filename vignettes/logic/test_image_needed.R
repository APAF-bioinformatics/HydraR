# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test_image_needed.R
# Author:      APAF Agentic Workflow
# Purpose:     Image check test node logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(out) {
  isTRUE(out$needs_generation)
}

# <!-- APAF Bioinformatics | test_image_needed.R | Approved | 2026-04-03 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        spec_prompt.R
# Author:      APAF Agentic Workflow
# Purpose:     Specialized bioinformatician prompt logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  sprintf("Process and summarize the following biological data: %s", state$get("input"))
}

# <!-- APAF Bioinformatics | spec_prompt.R | Approved | 2026-04-03 -->

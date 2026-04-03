# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        image_prompt.R
# Author:      APAF Agentic Workflow
# Purpose:     Image prompt logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  sprintf(
    "Generate five high-quality travel photography prompts for the following locations in Hong Kong: %s.",
    paste(state$get("must_include"), collapse = ", ")
  )
}

# <!-- APAF Bioinformatics | image_prompt.R | Approved | 2026-04-03 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        plan_prompt.R
# Author:      APAF Agentic Workflow
# Purpose:     Travel planning prompt logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  sprintf(
    "Plan a trip from %s to %s from %s to %s on %s. Must include: %s.",
    state$get("origin"), state$get("destination"),
    state$get("departure_date"), state$get("return_date"),
    state$get("airline"), paste(state$get("must_include"), collapse = ", ")
  )
}

# <!-- APAF Bioinformatics | plan_prompt.R | Approved | 2026-04-03 -->

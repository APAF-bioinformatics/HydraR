# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        check_fixed.R
# Author:      APAF Agentic Workflow
# Purpose:     Pause/Resume logic for persistence testing
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  if (!isTRUE(state$get("fixed"))) {
    # Return "PAUSE" status - HydraR saves state and stops cleanly
    return(list(status = "PAUSE", output = "Waiting for manual fix."))
  }
  list(status = "SUCCESS", output = "System recovered!")
}

# <!-- APAF Bioinformatics | check_fixed.R | Approved | 2026-04-03 -->

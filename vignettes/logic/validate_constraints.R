# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        validate_constraints.R
# Author:      APAF Agentic Workflow
# Purpose:     Constraint validation logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  itinerary <- state$get("Planner") %||% ""
  must_include <- state$get("must_include")
  found <- purrr::map_lgl(must_include, function(x) {
    grepl(x, itinerary, ignore.case = TRUE)
  })

  report <- paste0(
    "### Constraint Audit Report\n",
    "Date: ", Sys.time(), "\n",
    paste0("- [", ifelse(found, "x", " "), "] ", must_include, collapse = "\n")
  )

  if (all(found)) {
    list(status = "SUCCESS", output = list(validation_passed = TRUE, report = report))
  } else {
    missing <- must_include[!found]
    list(status = "SUCCESS", output = list(
      validation_passed = FALSE,
      message = paste("Missing:", paste(missing, collapse = ", ")),
      report = report
    ))
  }
}

# <!-- APAF Bioinformatics | validate_constraints.R | Approved | 2026-04-03 -->

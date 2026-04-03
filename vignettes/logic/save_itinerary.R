# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        save_itinerary.R
# Author:      APAF Agentic Workflow
# Purpose:     Itinerary saving logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  itinerary <- state$get("Planner")
  pamphlet <- state$get("PamphletFormatter")
  # Note: logic node outputs are merged into state root by AgentState$set()
  validation_passed <- state$get("validation_passed")
  report <- state$get("report")
  
  base_path <- if (dir.exists("vignettes")) "vignettes/" else ""
  
  if (!is.null(itinerary)) {
    # Save itinerary
    itinerary_path <- paste0(base_path, "hong_kong_itinerary.md")
    writeLines(as.character(itinerary), itinerary_path)
    message("Saved itinerary to: ", itinerary_path)
    
    # Save pamphlet
    if (!is.null(pamphlet)) {
      pamphlet_path <- paste0(base_path, "hong_kong_pamphlet.html")
      full_html <- sprintf("<!DOCTYPE html><html><head><meta charset='utf-8'><title>HK Travel Pamphlet</title></head><body>%s</body></html>", pamphlet)
      writeLines(full_html, pamphlet_path)
      message("Saved pamphlet to: ", pamphlet_path)
    }
    
    # Save validation report
    if (!is.null(report)) {
      report_path <- paste0(base_path, "validation_report.md")
      writeLines(as.character(report), report_path)
      message("Saved validation report to: ", report_path)
    } else {
      warning("No validation report found in state.")
    }
    
    list(status = "SUCCESS", output = "All artifacts saved successfully.")
  } else {
    list(status = "FAILED", output = "No itinerary found in state.")
  }
}

# <!-- APAF Bioinformatics | save_itinerary.R | Approved | 2026-04-03 -->

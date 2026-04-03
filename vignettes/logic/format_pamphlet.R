# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        format_pamphlet.R
# Author:      APAF Agentic Workflow
# Purpose:     HTML formatting logic for the pamphlet
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  itinerary <- state$get("Planner")
  template <- state$get("TemplateManager")
  destination <- state$get("destination")
  
  # Split itinerary into roughly 5 parts for columns 2-6
  itinerary_lines <- strsplit(itinerary, "\n")[[1]]
  itinerary_lines <- itinerary_lines[itinerary_lines != ""] 
  
  n <- length(itinerary_lines)
  col_size <- ceiling(n / 5)
  
  # Refactored APAF Rule G-25: No for-loops
  parts <- purrr::map(1:5, function(i) {
    start <- ((i - 1) * col_size) + 1
    end <- min(i * col_size, n)
    if (start <= n) {
      paste(itinerary_lines[start:end], collapse = "\n")
    } else {
      ""
    }
  })
  
  render_md <- function(x) {
    if (requireNamespace("commonmark", quietly = TRUE)) {
      commonmark::markdown_html(x)
    } else {
      gsub("\n", "<br/>", x) 
    }
  }

  html_out <- template
  html_out <- gsub("{{TITLE}}", paste("Explore", destination), html_out, fixed = TRUE)
  html_out <- gsub("{{COL2}}", render_md(parts[[1]]), html_out, fixed = TRUE)
  html_out <- gsub("{{COL3}}", render_md(parts[[2]]), html_out, fixed = TRUE)
  html_out <- gsub("{{COL4}}", render_md(parts[[3]]), html_out, fixed = TRUE)
  html_out <- gsub("{{COL5}}", render_md(parts[[4]]), html_out, fixed = TRUE)
  html_out <- gsub("{{COL6}}", render_md(parts[[5]]), html_out, fixed = TRUE)
  
  list(status = "SUCCESS", output = html_out)
}

# <!-- APAF Bioinformatics | format_pamphlet.R | Approved | 2026-04-03 -->

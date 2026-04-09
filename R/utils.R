# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        utils.R
# Author:      APAF Agentic Workflow
# Purpose:     Shared Utility Functions for HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Extract R Code from LLM Response
#'
#' @param raw String. Raw text response from LLM.
#' @return String. Extracted R code or same text if no blocks found.
#' @examples
#' \dontrun{
#' extract_r_code_advanced("```r\nprint(1)\n```")
#' }
#' @export
extract_r_code_advanced <- function(raw) {
  if (is.null(raw) || length(raw) == 0 || raw == "") {
    return("")
  }

  # 1. Look for ```r ... ``` blocks (case insensitive)
  # Using lazy match to capture individual blocks
  matches <- regmatches(raw, gregexpr("(?s)```[rR]\\s*\\n(.*?)```", raw, perl = TRUE))[[1]]

  if (length(matches) > 0) {
    # Strip the fences from all blocks and concatenate
    clean_blocks <- purrr::map_chr(matches, function(m) {
      gsub("^```[rR]\\s*\\n?|\\n?```$", "", m)
    })
    return(trimws(paste(clean_blocks, collapse = "\n\n")))
  }

  # 2. Fallback: Entire text if it looks like R code (heuristic)
  if (grepl("<-|library\\(|%>%|\\|>|function\\(", raw)) {
    return(trimws(raw))
  }

  return(trimws(raw))
}

#' Null-coalescing operator
#' @param a Any value.
#' @param b Fallback value.
#' @return a if not null, else b.
#' @noRd
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

#' Check if an object is a named list
#'
#' @description
#' Helper to verify that an object is a list (but not a data.frame) and
#' that all its elements have non-empty names.
#'
#' @param x Any object.
#' @return Logical.
#' @examples
#' \dontrun{
#' is_named_list(list(a = 1))
#' }
#' @export
is_named_list <- function(x) {
  is.list(x) && !is.data.frame(x) && !is.null(names(x)) && all(nzchar(names(x)))
}

#' <!-- APAF Bioinformatics | utils.R | Approved | 2026-03-29 -->

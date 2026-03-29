# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        registry.R
# Author:      APAF Agentic Workflow
# Purpose:     Logic Registry for serializable R functions
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

# Internal environment for storing function logic
.hydra_registry <- new.env(parent = emptyenv())

#' Register Logic Function
#' @param name String. Unique identifier for the function.
#' @param fn Function. The R function to store.
#' @return The registry environment (invisibly).
#' @export
register_logic <- function(name, fn) {
  stopifnot(is.character(name) && is.function(fn))
  assign(name, fn, envir = .hydra_registry)
  invisible(.hydra_registry)
}

#' Get Logic Function
#' @param name String. Unique identifier.
#' @return Function or NULL.
#' @export
get_logic <- function(name) {
  if (exists(name, envir = .hydra_registry)) {
    return(get(name, envir = .hydra_registry))
  }
  return(NULL)
}

#' List Registered Components
#' @return Character vector of names.
#' @export
list_logic <- function() {
  ls(envir = .hydra_registry)
}

# <!-- APAF Bioinformatics | registry.R | Approved | 2026-03-29 -->

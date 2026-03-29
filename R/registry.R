# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        registry.R
# Author:      APAF Agentic Workflow
# Purpose:     Logic Registry for serializable R functions
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' HydraR Logic Registry
#'
#' @description
#' An internal environment mapping names to functions for reducers and schemas.
#' This allows saving AgentState as JSON by only storing function names.
#'
#' @keywords internal
.hydra_registry <- new.env(parent = emptyenv())

#' Register a Logic Component
#'
#' @param name String. Unique name for the component.
#' @param fn Function. The R function to register.
#' @return NULL (called for side effect).
#' @export
register_logic <- function(name, fn) {
  if (!is.character(name) || length(name) != 1) stop("name must be a single string.")
  if (!is.function(fn)) stop("fn must be a function.")
  assign(name, fn, envir = .hydra_registry)
  invisible(NULL)
}

#' Get a Registered Logic Component
#'
#' @param name String.
#' @return The function or NULL if not found.
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

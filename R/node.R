#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        node.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Abstract Base Agent Node Class for HydraR
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Agent Node R6 Class
#'
#' @description
#' Represents a single execution unit within an orchestration DAG.
#' This is an abstract base class.
#'
#' @importFrom R6 R6Class
#' @export
AgentNode <- R6::R6Class("AgentNode",
    public = list(
        #' @field id String. Unique identifier for the node.
        id = NULL,
        #' @field last_result List. Results from most recent execution.
        last_result = NULL,

        #' Initialize AgentNode
        #' @param id Unique identifier.
        initialize = function(id) {
            stopifnot(is.character(id) && length(id) == 1)
            self$id <- id
        },

        #' Run the Node
        #' @param state AgentState object.
        #' @param ... Additional arguments.
        #' @return List with status, output, and metadata.
        run = function(state, ...) {
            stop("Method 'run' must be implemented by subclass.")
        }
    )
)

# <!-- APAF Bioinformatics | node.R | Approved | 2026-03-28 -->

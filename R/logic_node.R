#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        logic_node.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Agent Node for pure R logic (non-LLM)
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Agent Logic Node R6 Class
#'
#' @description
#' A specialized AgentNode that executes a pure R function instead of an LLM call.
#'
#' @importFrom R6 R6Class
#' @export
AgentLogicNode <- R6::R6Class("AgentLogicNode",
    inherit = AgentNode,
    public = list(
        #' @field logic_fn Function(state) -> List(status, output).
        logic_fn = NULL,

        #' Initialize AgentLogicNode
        #' @param id Unique identifier.
        #' @param logic_fn Function that takes an AgentState object and returns a list.
        initialize = function(id, logic_fn) {
            super$initialize(id)
            stopifnot(is.function(logic_fn))
            self$logic_fn <- logic_fn
        },

        #' Run the Logic Node
        #' @param state AgentState object.
        #' @return List with status, output, and metadata.
        run = function(state, ...) {
            cat(sprintf("   [%s] Executing R logic...\n", self$id))
            
            res <- tryCatch(
                {
                    self$logic_fn(state)
                },
                error = function(e) {
                    list(status = "FAILED", output = NULL, error = e$message)
                }
            )
            
            self$last_result <- list(
                status = res$status %||% "SUCCESS",
                output = res$output,
                error = res$error,
                attempts = 1
            )
            return(self$last_result)
        }
    )
)

# <!-- APAF Bioinformatics | logic_node.R | Approved | 2026-03-28 -->

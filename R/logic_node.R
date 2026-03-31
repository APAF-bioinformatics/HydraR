# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        logic_node.R
# Author:      APAF Agentic Workflow
# Purpose:     Agent Node for pure R logic (non-LLM)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Logic Node R6 Class
#'
#' @description
#' A node that executes a synchronous R function.
#'
#' @return An `AgentLogicNode` object.
#' @examples
#' node <- AgentLogicNode$new("start", function(state) list(status = "success"))
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
    #' @param label Optional human-readable name.
    #' @param params Optional list of parameters.
    initialize = function(id, logic_fn, label = NULL, params = list()) {
      super$initialize(id, label = label, params = params)
      stopifnot(is.function(logic_fn))
      self$logic_fn <- logic_fn
    },

    #' Run the Logic Node
    #' @param state AgentState object.
    #' @param ... Additional arguments.
    #' @return List with status, output, and metadata.
    run = function(state, ...) {
      cat(sprintf("   [%s] Executing R logic...\n", self$id))

      res <- tryCatch(
        {
          self$logic_fn(state)
        },
        error = function(e) {
          list(status = "failed", output = NULL, error = e$message)
        }
      )

      self$last_result <- list(
        status = res$status %||% "success",
        output = res$output,
        error = res$error,
        attempts = 1
      )
      return(self$last_result)
    }
  )
)

#' <!-- APAF Bioinformatics | logic_node.R | Approved | 2026-03-28 -->

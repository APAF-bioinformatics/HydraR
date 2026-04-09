# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        router_node.R
# Author:      APAF Agentic Workflow
# Purpose:     Agent Node for Dynamic Routing
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Router Node R6 Class
#'
#' @description
#' A node that determines the next node in the DAG dynamically.
#' The logic function must return a list with a `target_node` field.
#'
#' @return An `AgentRouterNode` object.
#' @examples
#' \dontrun{
#' node <- AgentRouterNode$new(id = "r1", route_fn = function(s) "next_node")
#' }
#' @export
AgentRouterNode <- R6::R6Class("AgentRouterNode",
  inherit = AgentNode,
  public = list(
    #' @field router_fn Function(state) -> List(target_node, output).
    router_fn = NULL,

    #' @description Initialize AgentRouterNode
    #' @param id Unique identifier.
    #' @param router_fn Function that takes an AgentState and returns a list.
    #' @param label Optional human-readable name.
    #' @param params Optional list of parameters.
    initialize = function(id, router_fn, label = NULL, params = list()) {
      super$initialize(id, label = label, params = params)
      stopifnot(is.function(router_fn))
      self$router_fn <- router_fn
    },

    #' Run the Router Node
    #' @param state AgentState object.
    #' @param ... Additional arguments.
    #' @return List with status, output, and target_node.
    run = function(state, ...) {
      cat(sprintf("   [%s] Executing Dynamic Router...\n", self$id))

      res <- tryCatch(
        {
          self$router_fn(state)
        },
        error = function(e) {
          list(status = "failed", output = NULL, error = e$message)
        }
      )

      self$last_result <- list(
        status = res$status %||% "success",
        output = res$output,
        target_node = res$target_node,
        error = res$error,
        attempts = 1
      )
      return(self$last_result)
    }
  )
)

# <!-- APAF Bioinformatics | router_node.R | Approved | 2026-03-31 -->

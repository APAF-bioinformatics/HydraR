# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        node.R
# Author:      APAF Agentic Workflow
# Purpose:     Abstract Base Agent Node Class for HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Node Base Class
#'
#' @description
#' The base R6 class for all nodes in an AgentDAG.
#'
#' @return An `AgentNode` object.
#' @examples
#' node <- AgentNode$new("my_node", label = "Custom Node")
#' @export
AgentNode <- R6::R6Class("AgentNode",
  public = list(
    #' @field id String. Unique identifier for the node.
    id = NULL,
    #' @field label String. Human-readable name/label.
    label = NULL,
    #' @field last_result List. Results from most recent execution.
    last_result = NULL,
    #' @field params List. Arbitrary metadata/config parameters.
    params = list(),

    #' Initialize AgentNode
    #' @param id Unique identifier.
    #' @param label Optional human-readable name.
    #' @param params Optional named list of parameters.
    initialize = function(id, label = NULL, params = list()) {
      stopifnot(is.character(id) && length(id) == 1)
      self$id <- id
      self$label <- label %||% id
      self$params <- params %||% list()
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

#' <!-- APAF Bioinformatics | node.R | Approved | 2026-03-28 -->

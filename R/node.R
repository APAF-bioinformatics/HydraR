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
#' The abstract base R6 class for all nodes within an \code{AgentDAG}.
#' It defines the common interface and fields required for any node to be
#' orchestrated by the HydraR engine. Subclasses must implement the \code{run()}
#' method.
#'
#' @return An \code{AgentNode} object.
#' @examples
#' # Defining a custom subclass of AgentNode
#' CustomNode <- R6::R6Class("CustomNode",
#'   inherit = AgentNode,
#'   public = list(
#'     run = function(state, ...) {
#'       message("Executing custom node: ", self$id)
#'       list(status = "success", output = "Custom output")
#'     }
#'   )
#' )
#'
#' node <- CustomNode$new("node_1", label = "My First Node")
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

    #' @description Initialize AgentNode
    #' @param id String.
    #' A unique identifier for the node. Must be unique within a single DAG.
    #' @param label String.
    #' An optional human-readable name for the node. Defaults to the \code{id}
    #' if not provided. This label is used in Mermaid visualizations.
    #' @param params List.
    #' An optional named list of arbitrary metadata or configuration parameters
    #' that are stored on the node and can be accessed during execution.
    #' Useful for passing static configuration to nodes created via factories.
    initialize = function(id, label = NULL, params = list()) {
      stopifnot(is.character(id) && length(id) == 1)
      self$id <- id
      self$label <- label %||% id
      self$params <- params %||% list()
    },

    #' Run the Node
    #' @param state AgentState.
    #' An \code{AgentState} object (typically a \code{RestrictedState}) providing
    #' scoped access to the centralized workflow memory.
    #' @param ... Additional arguments.
    #' Arbitrary parameters passed from \code{AgentDAG$run()}.
    #' @return A list with at least \code{status} (String, e.g., "success", "failed", "pause")
    #' and \code{output} (Any R object to be integrated back into the state).
    run = function(state, ...) {
      stop("Method 'run' must be implemented by subclass.")
    }
  )
)

#' <!-- APAF Bioinformatics | node.R | Approved | 2026-03-28 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        observer_node.R
# Author:      APAF Agentic Workflow
# Purpose:     Agent Node for Side-Effects (Non-Blocking Logic)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Observer Node R6 Class
#'
#' @description
#' A node that executes logic for side-effects (e.g., logging, notifications).
#' Its output does not modify the primary AgentState.
#'
#' @return An `AgentObserverNode` object.
#' @export
AgentObserverNode <- R6::R6Class("AgentObserverNode",
  inherit = AgentNode,
  public = list(
    #' @field observe_fn Function(state) -> void.
    observe_fn = NULL,

    #' @description Initialize AgentObserverNode
    #' @param id Unique identifier.
    #' @param observe_fn Function that takes an AgentState.
    #' @param label Optional label.
    #' @param params Optional parameters.
    initialize = function(id, observe_fn, label = NULL, params = list()) {
      super$initialize(id, label = label, params = params)
      stopifnot(is.function(observe_fn))
      self$observe_fn <- observe_fn
    },

    #' Run the Observer Node
    #' @param state AgentState or RestrictedState object.
    #' @param ... Additional arguments.
    #' @return List with status "observer" and NULL output.
    run = function(state, ...) {
      cat(sprintf("   [%s] Observing with side-effects...\n", self$id))

      # Wrap in read-only RestrictedState to enforce observer contract
      ro_state <- if (inherits(state, "RestrictedState")) {
        RestrictedState$new(state$state, state$node_id, state$logger, read_only = TRUE)
      } else if (inherits(state, "AgentState")) {
        RestrictedState$new(state, self$id, read_only = TRUE)
      } else {
        state
      }

      tryCatch(
        {
          self$observe_fn(ro_state)
        },
        error = function(e) {
          warning(sprintf("[%s] Observer failed: %s", self$id, e$message))
        }
      )

      self$last_result <- list(
        status = "observer",
        output = NULL,
        error = NULL,
        attempts = 1
      )
      return(self$last_result)
    }
  )
)

# <!-- APAF Bioinformatics | observer_node.R | Approved | 2026-03-31 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        state.R
# Author:      APAF Agentic Workflow
# Purpose:     Centralized State Management for HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent State R6 Class
#'
#' @description
#' A strongly typed, centrally managed state object for passing data
#' between nodes in an AgentDAG.
#'
#' @importFrom R6 R6Class
#' @importFrom purrr iwalk walk
#' @export
AgentState <- R6::R6Class("AgentState",
  public = list(
    #' @field data Environment. Stores state variables.
    data = NULL,
    #' @field reducers List. Functions applied to merge updates.
    reducers = list(),
    #' @field schema List. Expected types for state variables.
    schema = list(),

    #' Initialize AgentState
    #' @param initial_data List of initial state variables or String.
    #' @param reducers Named list of reducer functions.
    #' @param schema Named list of expected types.
    initialize = function(initial_data = list(), reducers = list(), schema = list()) {
      self$data <- new.env(parent = emptyenv())
      self$reducers <- reducers
      self$schema <- schema

      if (is.list(initial_data)) {
        purrr::iwalk(initial_data, function(val, key) {
          self$set(key, val)
        })
      } else if (is.character(initial_data)) {
        # Fallback for simple string input
        self$set("input", initial_data)
      } else {
        stop("initial_data must be a list or a character string.")
      }
    },

    #' Get a state variable
    #' @param key String.
    #' @param default Value to return if key not found.
    #' @return The value.
    get = function(key, default = NULL) {
      if (exists(key, envir = self$data)) {
        return(get(key, envir = self$data))
      }
      return(default)
    },

    #' Get all state variables as a list
    #' @return A named list.
    get_all = function() {
      as.list(self$data)
    },

    #' Validate a single state variable against the schema
    #' @param key String.
    #' @param value Any value.
    #' @return TRUE if valid, throws error otherwise.
    validate = function(key, value) {
      if (key %in% names(self$schema)) {
        expected_type <- self$schema[[key]]
        if (!inherits(value, expected_type) && typeof(value) != expected_type) {
          stop(sprintf(
            "Schema validation failed for '%s': expected %s, got %s",
            key, expected_type, typeof(value)
          ))
        }
      }
      TRUE
    },

    #' Set a state variable directly (bypassing reducers)
    #' @param key String.
    #' @param value Any value.
    set = function(key, value) {
      self$validate(key, value)
      assign(key, value, envir = self$data)
      invisible(self)
    },

    #' Update state using reducers
    #' @param updates List of state updates.
    update = function(updates) {
      if (!is.list(updates)) {
        return(invisible(self))
      }

      purrr::iwalk(updates, function(val, key) {
        # If a reducer exists for this key, apply it
        if (!is.null(self$reducers[[key]])) {
          current_val <- self$get(key)
          new_val <- self$reducers[[key]](current_val, val)
          self$set(key, new_val)
        } else {
          # Default: simple replacement
          self$set(key, val)
        }
      })
      invisible(self)
    }
  )
)

#' Built-in Reducer: Append
#'
#' Appends new elements to a vector or list. For large accumulations,
#' users should consider using lists and flattening later.
#' @param current The current state value.
#' @param new The new value to append.
#' @return The combined value.
#' @export
reducer_append <- function(current, new) {
  if (is.null(current)) {
    return(new)
  }
  # R's c() is efficient for small-to-medium objects
  c(current, new)
}

#' Built-in Reducer: Merge List
#'
#' Merges two named lists using functional patterns.
#' Overwrites current for matching keys.
#' @param current The current state list.
#' @param new The new list to merge.
#' @return The merged list.
#' @export
reducer_merge_list <- function(current, new) {
  if (is.null(current)) {
    return(new)
  }
  if (!is.list(current) || !is.list(new)) {
    stop("reducer_merge_list requires both arguments to be lists")
  }

  # Use utils::modifyList for robust, side-effect-free list merging
  utils::modifyList(current, new, keep.null = TRUE)
}

#' <!-- APAF Bioinformatics | state.R | Approved | 2026-03-28 -->

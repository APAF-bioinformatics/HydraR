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
#' @return An `AgentState` R6 object.
#' @examples
#' state <- AgentState$new(initial_data = list(topic = "R"))
#' state$get("topic")
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

    #' @description Initialize AgentState
    #' @param initial_data List of initial state variables or String.
    #' @param reducers Named list of reducer functions.
    #' @param schema Named list of expected types.
    initialize = function(initial_data = list(), reducers = list(), schema = list()) {
      self$data <- new.env(parent = emptyenv())

      # Resolve reducers if they are character names
      self$reducers <- purrr::map(reducers, function(fn_or_name) {
        if (is.character(fn_or_name)) {
          resolved <- get_logic(fn_or_name)
          if (is.null(resolved)) stop(sprintf("Reducer '%s' not found in Logic Registry.", fn_or_name))
          return(resolved)
        }
        fn_or_name
      })

      # Resolve schema if keys are names (optional enhancement)
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
    },

    #' Update state from a node's output
    #' @param output The output from the node.
    #' @param node_id The ID of the node.
    update_from_node = function(output, node_id) {
      if (is_named_list(output)) {
        self$update(output)
      } else {
        self$update(stats::setNames(list(output), node_id))
      }
      invisible(self)
    },

    #' Export state for persistence (logic as names)
    #' @return List.
    to_list_serializable = function() {
      # Find names for reducers in registry
      reducer_names <- purrr::map(self$reducers, function(fn) {
        # Look up in registry
        all_logic <- ls(envir = .hydra_registry)
        match_idx <- purrr::detect_index(all_logic, function(name) {
          identical(get(name, envir = .hydra_registry), fn)
        })
        if (match_idx > 0) {
          return(all_logic[match_idx])
        }
        return(NULL) # anonymous function, not serializable to JSON readability cleanly
      })

      list(
        data = self$get_all(),
        reducers = reducer_names,
        schema = self$schema
      )
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
#' @examples
#' \dontrun{
#' reducer_append(1, 2)
#' }
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
#' @examples
#' \dontrun{
#' reducer_merge_list(list(a = 1), list(b = 2))
#' }
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

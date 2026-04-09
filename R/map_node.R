# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        map_node.R
# Author:      APAF Agentic Workflow
# Purpose:     Agent Node for Mapping over Lists
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Map Node R6 Class
#'
#' @description
#' A node that maps over a list in the state and performs an operation.
#'
#' @return An `AgentMapNode` object.
#' @examples
#' \dontrun{
#' # Mapping over a list of URLs to fetch data
#' fetch_logic <- function(url, state) {
#'   # Custom logic for each item
#'   list(status = "success", output = paste0("Data from ", url))
#' }
#'
#' node_map <- AgentMapNode$new(
#'   id = "batch_fetcher",
#'   map_key = "url_list",
#'   logic_fn = fetch_logic
#' )
#'
#' # Setup state with items to map over
#' state <- AgentState$new(list(url_list = c("url1", "url2", "url3")))
#' results <- node_map$run(state)
#' }
#' @export
AgentMapNode <- R6::R6Class("AgentMapNode",
  inherit = AgentNode,
  public = list(
    #' @field map_key String. Key in state to map over.
    map_key = NULL,
    #' @field logic_fn Function(item, state) -> List(status, output).
    logic_fn = NULL,

    #' @description Initialize AgentMapNode
    #' @param id Unique identifier.
    #' @param map_key String identifier for state retrieval.
    #' @param logic_fn Mapping function.
    #' @param label Optional label.
    #' @param params Optional parameters.
    initialize = function(id, map_key, logic_fn, label = NULL, params = list()) {
      super$initialize(id, label = label, params = params)
      stopifnot(is.character(map_key) && length(map_key) == 1)
      stopifnot(is.function(logic_fn))
      self$map_key <- map_key
      self$logic_fn <- logic_fn
    },

    #' Run the Map Node
    #' @param state AgentState object.
    #' @param ... Additional arguments.
    #' @return List with status, output (list of results).
    run = function(state, ...) {
      cat(sprintf("   [%s] Executing Mapping Logic over '%s'...\n", self$id, self$map_key))

      items <- state$get(self$map_key)
      if (is.null(items)) {
        return(list(status = "skip", output = "Map key not found in state."))
      }

      # Use purrr::map for sequential mapping by default
      results <- purrr::map(items, function(item) {
        tryCatch(
          {
            self$logic_fn(item, state)
          },
          error = function(e) {
            list(status = "failed", output = NULL, error = e$message)
          }
        )
      })

      self$last_result <- list(
        status = "success",
        output = results,
        error = NULL,
        attempts = 1
      )
      return(self$last_result)
    }
  )
)

# <!-- APAF Bioinformatics | map_node.R | Approved | 2026-03-31 -->

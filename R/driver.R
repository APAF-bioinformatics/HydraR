# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        driver.R
# Author:      APAF Agentic Workflow
# Purpose:     Abstract Agent Driver Base Class
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Driver R6 Class
#'
#' @description
#' Abstract base class for CLI-based LLM drivers.
#'
#' @importFrom R6 R6Class
#' @export
AgentDriver <- R6::R6Class("AgentDriver",
    public = list(
        #' @field id String. Unique identifier for the driver.
        id = NULL,

        #' Initialize AgentDriver
        #' @param id Unique identifier.
        initialize = function(id) {
            stopifnot(is.character(id) && length(id) == 1)
            self$id <- id
        },

        #' Call the LLM
        #' @param prompt String. The prompt to send.
        #' @param model String. Optional model override.
        #' @param ... Additional arguments.
        #' @return String. Cleaned response from the LLM.
        call = function(prompt, model = NULL, ...) {
            stop("Abstract Method: call() must be implemented by subclass.")
        }
    )
)

#' <!-- APAF Bioinformatics | driver.R | Approved | 2026-03-28 -->

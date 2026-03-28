#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        node_llm.R
#' Author:      APAF Agentic Workflow
#' Purpose:     LLM-Based Agent Node Class for HydraR
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Agent LLM Node R6 Class
#'
#' @description
#' A specialized AgentNode that executes LLM calls via a Driver.
#'
#' @importFrom R6 R6Class
#' @export
AgentLLMNode <- R6::R6Class("AgentLLMNode",
    inherit = AgentNode,
    public = list(
        #' @field role String. System prompt/role for the agent.
        role = NULL,
        #' @field model String. Default model.
        model = NULL,
        #' @field driver AgentDriver object.
        driver = NULL,
        #' @field output_format String. Output expectation.
        output_format = "text",
        #' @field prompt_builder Function(state) -> String.
        prompt_builder = NULL,
        #' @field tools List of AgentTool objects.
        tools = list(),

        #' Initialize AgentLLMNode
        #' @param id Unique identifier.
        #' @param role System prompt.
        #' @param driver AgentDriver object.
        #' @param model String. Optional model override.
        #' @param prompt_builder Function(state) -> String.
        #' @param tools List of AgentTool objects.
        initialize = function(id, role, driver, model = NULL, prompt_builder = NULL, tools = list()) {
            super$initialize(id)
            stopifnot(is.character(role) && length(role) == 1)
            stopifnot(inherits(driver, "AgentDriver"))
            
            self$role <- role
            self$driver <- driver
            self$model <- model
            self$prompt_builder <- prompt_builder
            self$tools <- tools
        },

        #' Run the LLM Node
        #' @param state AgentState object.
        #' @param ... Additional arguments.
        #' @return List with status, output, and metadata.
        run = function(state, ...) {
            # Determine prompt suffix
            input_text <- if (!is.null(self$prompt_builder)) {
                self$prompt_builder(state)
            } else {
                # Fallback: simple state summary
                jsonlite::toJSON(state$get_all(), auto_unbox = TRUE)
            }
            
            # Construct prompt
            tool_injection <- format_toolset(self$tools)
            full_prompt <- sprintf("System: %s%s\n\nUser: %s", self$role, tool_injection, input_text)
            
            # Use Driver
            raw_response <- tryCatch(
                {
                    self$driver$call(prompt = full_prompt, model = self$model, ...)
                },
                error = function(e) {
                    warning(sprintf("[%s] LLM driver call failed: %s", self$id, e$message))
                    return(NULL)
                }
            )
            
            if (is.null(raw_response)) {
                self$last_result <- list(status = "FAILED", output = NULL, error = "Driver Error", attempts = 1)
                return(self$last_result)
            }
            
            self$last_result <- list(
                status = "SUCCESS",
                output = raw_response,
                raw = raw_response,
                attempts = 1
            )
            return(self$last_result)
        }
    )
)

# <!-- APAF Bioinformatics | node_llm.R | Approved | 2026-03-28 -->

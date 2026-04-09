# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        tools.R
# Author:      APAF Agentic Workflow
# Purpose:     AgentTool Class and Registry for Prompt Injection
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Tool R6 Class
#'
#' @description
#' Defines a tool or action that an agent can perform.
#' Used for prompt-based tool discovery.
#'
#' @importFrom R6 R6Class
#' @return An `AgentTool` object.
#' @examples
#' \dontrun{
#' # Define a tool for searching genomic databases
#' tool <- AgentTool$new(
#'   name = "blast_search",
#'   description = "Perform a BLAST search against the NCBI non-redundant database.",
#'   parameters = list(
#'     query = "The DNA sequence string",
#'     evalue = "The e-value threshold (default 1e-5)"
#'   ),
#'   example = "blast_search(query='ATGC...', evalue=0.001)"
#' )
#'
#' # Format for injection into a system prompt
#' message(tool$format())
#' }
#' @export
AgentTool <- R6::R6Class("AgentTool",
  public = list(
    #' @field name String. The unique name of the tool.
    name = NULL,
    #' @field description String. A clear description of what the tool does.
    description = NULL,
    #' @field parameters List. A description of the expected parameters.
    parameters = NULL,
    #' @field example String. An example of how to use the tool.
    example = NULL,

    #' @description Initialize AgentTool
    #' @param name String.
    #' @param description String.
    #' @param parameters List or String.
    #' @param example String.
    initialize = function(name, description, parameters = list(), example = "") {
      stopifnot(is.character(name) && length(name) == 1)
      stopifnot(is.character(description) && length(description) == 1)

      self$name <- name
      self$description <- description
      self$parameters <- parameters
      self$example <- example
    },

    #' Format for Prompt
    #' @return A formatted string describing the tool.
    format = function() {
      fmt <- sprintf("- Tool: %s\n  Description: %s\n", self$name, self$description)
      if (length(self$parameters) > 0) {
        params_str <- if (is.list(self$parameters)) {
          paste(names(self$parameters), ":", unlist(self$parameters), collapse = "; ")
        } else {
          as.character(self$parameters)
        }
        fmt <- paste0(fmt, sprintf("  Parameters: %s\n", params_str))
      }
      if (!is.null(self$example) && self$example != "") {
        fmt <- paste0(fmt, sprintf("  Example: %s\n", self$example))
      }
      return(fmt)
    }
  )
)

#' Format Toolset for Prompt
#' @param tools List of AgentTool objects.
#' @return A formatted string containing all tool descriptions.
#' @examples
#' \dontrun{
#' # Format a collection of tools for an agent
#' tools <- list(
#'   search = AgentTool$new("google_search", "Search the web"),
#'   run_r = AgentTool$new("r_exec", "Execute R code locally")
#' )
#'
#' prompt_appendix <- format_toolset(tools)
#' cat(prompt_appendix)
#' }
#' @export
format_toolset <- function(tools) {
  if (length(tools) == 0) {
    return("")
  }

  header <- "\n### AVAILABLE TOOLS ###\n"
  tool_descriptions <- vapply(tools, function(t) {
    if (inherits(t, "AgentTool")) t$format() else ""
  }, FUN.VALUE = character(1))

  footer <- "\nWhen you need to use a tool, specify the tool name and provide necessary parameters in the format requested by your system instructions.\n"

  paste0(header, paste(tool_descriptions, collapse = "\n"), footer)
}

#' <!-- APAF Bioinformatics | tools.R | Approved | 2026-03-28 -->

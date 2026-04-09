# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        node_llm.R
# Author:      APAF Agentic Workflow
# Purpose:     LLM-Based Agent Node Class for HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent LLM Node R6 Class
#'
#' @description
#' A specialized \code{AgentNode} that leverages a Large Language Model (LLM)
#' to generate outputs from prompts. It manages prompt construction by combining
#' a persistent \code{role} (system prompt) with dynamic context from the
#' \code{AgentState}. It also handles tool injection and automatic context
#' discovery from local files (e.g., \code{agents.md}, \code{skills.md}).
#'
#' @return An \code{AgentLLMNode} object.
#' @examples
#' \dontrun{
#' # NOTE: Set ANTHROPIC_API_KEY in your .Renviron file
#' driver <- AnthropicAPIDriver$new()
#'
#' # Create a node with a prompt builder that pulls from state
#' node <- AgentLLMNode$new(
#'   id = "summarizer",
#'   role = "You are a concise summarizer.",
#'   driver = driver,
#'   prompt_builder = function(state) {
#'     sprintf("Summarise this text: %s", state$get("input_text"))
#'   }
#' )
#' }
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
    #' @field cli_opts List. Default CLI options for the driver.
    cli_opts = list(),
    #' @field prompt_builder Function(state) -> String.
    prompt_builder = NULL,
    #' @field tools List of AgentTool objects.
    tools = list(),
    #' @field agents_files Character vector. Paths to agents context files.
    agents_files = NULL,
    #' @field skills_files Character vector. Paths to skills context files.
    skills_files = NULL,


    #' @description Initialize AgentLLMNode
    #' @param id String.
    #' Unique identifier for the node.
    #' @param role String.
    #' The primary system prompt or persona the LLM should assume.
    #' @param driver AgentDriver.
    #' An instance of an \code{AgentDriver} subclass (CLI or API based).
    #' @param model String.
    #' Optional. The specific model to use (overrides driver default).
    #' @param cli_opts List.
    #' Optional. Named list of parameters for the LLM call (e.g., temperature).
    #' @param prompt_builder Function.
    #' Optional. A function that takes an \code{AgentState} and returns a
    #' string prompt. If omitted, the node serializes the entire state as JSON.
    #' @param tools List.
    #' A list of \code{AgentTool} objects available for the agent to use.
    #' @param label String.
    #' Human-readable name for visualization.
    #' @param params List.
    #' Additional configuration (e.g., \code{output_format="r"}).
    #' @param agents_files Character vector.
    #' Optional paths to markdown files containing agent interaction guidelines.
    #' @param skills_files Character vector.
    #' Optional paths to markdown files containing specialized tool instructions.
    initialize = function(id, role, driver, model = NULL, cli_opts = list(), prompt_builder = NULL, tools = list(), label = NULL, params = list(), agents_files = NULL, skills_files = NULL) {
      super$initialize(id, label = label, params = params)
      stopifnot(is.character(role) && length(role) == 1)
      stopifnot(inherits(driver, "AgentDriver"))

      self$role <- role
      self$driver <- driver
      self$model <- model
      self$cli_opts <- cli_opts
      self$prompt_builder <- prompt_builder
      self$tools <- tools
      self$agents_files <- agents_files %||% params[["agents_files"]]
      self$skills_files <- skills_files %||% params[["skills_files"]]
    },


    #' Run the LLM Node
    #'
    #' @description
    #' Executes the LLM call. This method handles prompt construction,
    #' tool injection, context file discovery, and driver invocation.
    #'
    #' @param state AgentState.
    #' The centralized state object for the workflow.
    #' @param ... Additional arguments.
    #' Passed through to the driver's \code{call()} method.
    #' @return A list containing \code{status}, \code{output} (the LLM response),
    #' \code{raw} (the full driver response), and meta-information.
    run = function(state, ...) {
      # Determine prompt suffix
      input_text <- if (!is.null(self$prompt_builder)) {
        self$prompt_builder(state)
      } else {
        # Fallback: simple state summary (Sanitized to avoid R6 serialization issues)
        all_state <- state$get_all()
        # Filter out R6 and other unspeakable objects
        safe_state <- purrr::discard(all_state, ~ inherits(.x, "R6") || is.function(.x) || is.environment(.x))
        jsonlite::toJSON(safe_state, auto_unbox = TRUE)
      }

      # Construct System Prompt
      tool_injection <- format_toolset(self$tools)
      system_prompt <- sprintf("%s%s", self$role, tool_injection)

      # 1. Automatic Discovery from Worktree
      work_dir <- self$driver$working_dir
      if (!is.null(work_dir) && dir.exists(work_dir)) {
        agents_path <- file.path(work_dir, "agents.md")
        if (file.exists(agents_path)) {
          agents_md <- paste(readLines(agents_path, warn = FALSE), collapse = "\n")
          system_prompt <- paste0(system_prompt, "\n\n### Agents Context (agents.md)\n", agents_md)
        }

        skills_path <- file.path(work_dir, "skills.md")
        if (file.exists(skills_path)) {
          skills_md <- paste(readLines(skills_path, warn = FALSE), collapse = "\n")
          system_prompt <- paste0(system_prompt, "\n\n### Skills Context (skills.md)\n", skills_md)
        }
      }

      # 2. Explicit Static Paths (via agents_files / skills_files)
      if (length(self$agents_files) > 0) {
        purrr::walk(self$agents_files, function(f) {
          if (file.exists(f)) {
            content <- paste(readLines(f, warn = FALSE), collapse = "\n")
            system_prompt <<- paste0(system_prompt, "\n\n### Additional Agent Context (", basename(f), ")\n", content)
          }
        })
      }

      if (length(self$skills_files) > 0) {
        purrr::walk(self$skills_files, function(f) {
          if (file.exists(f)) {
            content <- paste(readLines(f, warn = FALSE), collapse = "\n")
            system_prompt <<- paste0(system_prompt, "\n\n### Additional Skills Context (", basename(f), ")\n", content)
          }
        })
      }

      # Use Driver
      raw_response <- tryCatch(
        {
          self$driver$call(
            prompt = input_text,
            model = self$model,
            system_prompt = system_prompt,
            cli_opts = self$cli_opts,
            ...
          )
        },
        error = function(e) {
          warning(sprintf("[%s] LLM driver call failed: %s", self$id, e$message))
          return(list(error = e$message))
        }
      )

      if (is.list(raw_response) && !is.null(raw_response$error)) {
        self$last_result <- list(status = "failed", output = NULL, error = raw_response$error, attempts = 1)
        return(self$last_result)
      }

      # 1. Automatic Code Extraction (if requested in params)
      output_res <- raw_response
      if (identical(self$params[["output_format"]], "r")) {
        output_res <- HydraR::extract_r_code_advanced(raw_response)
      }

      # 2. File Persistence (if output_path is provided in params)
      if (!is.null(self$params[["output_path"]])) {
        tryCatch(
          {
            writeLines(output_res, self$params[["output_path"]])
            # Optional: Automatic git tracking if in a worktree
            # We check system status or state for worktree indicator
            system2("git", c("add", shQuote(self$params[["output_path"]])), stdout = FALSE, stderr = FALSE)
            system2("git", c("commit", "-m", shQuote(sprintf("HydraR: Updated %s", self$id))), stdout = FALSE, stderr = FALSE)
          },
          error = function(e) {
            warning(sprintf("[%s] Failed to write/commit LLM output to '%s': %s", self$id, self$params[["output_path"]], e$message))
          }
        )
      }

      self$last_result <- list(
        status = "success",
        output = output_res,
        raw = raw_response,
        attempts = 1
      )
      return(self$last_result)
    },

    #' Swap Driver at Runtime
    #' @param driver AgentDriver object or String ID.
    swap_driver = function(driver) {
      if (is.character(driver)) {
        registry <- get_driver_registry()
        resolved <- registry$get(driver)
        if (is.null(resolved)) {
          stop(sprintf("Driver ID '%s' not found in registry. Register it before swapping.", driver))
        }
        self$driver <- resolved
      } else if (inherits(driver, "AgentDriver")) {
        self$driver <- driver
      } else {
        stop("driver must be an AgentDriver object or a registered driver ID.")
      }
      invisible(self)
    }
  )
)

#' <!-- APAF Bioinformatics | node_llm.R | Approved | 2026-03-28 -->

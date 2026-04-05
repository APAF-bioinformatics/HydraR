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
#' A node that uses an LLM driver for execution.
#'
#' @return An `AgentLLMNode` object.
#' @examples
#' \dontrun{
#' node <- AgentLLMNode$new("chat", role = "helpful assistant")
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
    #' @param id Unique identifier.
    #' @param role System prompt.
    #' @param driver AgentDriver object.
    #' @param model String. Optional model override.
    #' @param cli_opts List. Optional default CLI options.
    #' @param prompt_builder Function(state) -> String.
    #' @param tools List of AgentTool objects.
    #' @param label Optional human-readable name.
    #' @param params Optional list of parameters.
    #' @param agents_files Optional character vector of paths to agents.md files.
    #' @param skills_files Optional character vector of paths to skills.md files.
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
    #' @param state AgentState object.
    #' @param ... Additional arguments.
    #' @return List with status, output, and metadata.
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

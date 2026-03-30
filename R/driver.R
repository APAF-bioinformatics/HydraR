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
#' @return An `AgentDriver` R6 object.
#' @examples
#' \dontrun{
#' driver <- AgentDriver$new(id = "test", provider = "mock")
#' }
#' @importFrom R6 R6Class
#' @importFrom purrr imap
#' @export
AgentDriver <- R6::R6Class("AgentDriver",
  public = list(
    #' @field id String. Unique identifier for the driver.
    id = NULL,
    #' @field provider String. Provider name (e.g., "google", "ollama").
    provider = NULL,
    #' @field model_name String. The specific model identifier.
    model_name = NULL,
    #' @field supported_opts Character vector. Allowed CLI option names.
    supported_opts = character(0),
    #' @field validation_mode String. Either "warning" or "strict".
    validation_mode = "warning",
    #' @field working_dir String. Optional path to the working directory/worktree.
    working_dir = NULL,
    #' @field repo_root String. Path to the main repository root (for root-locked CLIs).
    repo_root = NULL,

    #' Initialize AgentDriver
    #' @param id Unique identifier.
    #' @param provider String. Provider name.
    #' @param model_name String. Model identifier.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional working directory.
    #' @param repo_root String. Path to the main repository root.
    initialize = function(id, provider = "unknown", model_name = "unknown",
                          validation_mode = "warning", working_dir = NULL,
                          repo_root = NULL) {
      stopifnot(is.character(id) && length(id) == 1)
      stopifnot(validation_mode %in% c("warning", "strict"))
      self$id <- id
      self$provider <- provider
      self$model_name <- model_name
      self$validation_mode <- validation_mode
      self$working_dir <- working_dir
      self$repo_root <- repo_root
    },

    #' Get Driver Capabilities
    #' @return List of logicals.
    get_capabilities = function() {
      list(
        streaming = FALSE,
        json_mode = FALSE,
        tools = FALSE
      )
    },

    #' Execute Command in Working Directory
    #' @description
    #' Safely executes a system command within the specified 'working_dir'
    #' using 'withr::with_dir' to ensure the original CWD is restored.
    #' @param command String. The command to run.
    #' @param args Character vector. Command arguments.
    #' @param ... Additional arguments passed to system2.
    #' @return Result of system2 call.
    exec_in_dir = function(command, args, ...) {
      res <- if (!is.null(self$working_dir)) {
        withr::with_dir(self$working_dir, {
          system2(command, args, ...)
        })
      } else {
        system2(command, args, ...)
      }

      # Check exit status
      status <- attr(res, "status") %||% 0L
      if (status != 0L) {
        # If stdout/stderr were captured, res itself contains the output
        err_msg <- if (is.character(res)) paste(res, collapse = "\n") else "Unknown CLI Error"
        stop(sprintf("[%s] CLI execution failed (exit code %d): %s", self$id, status, err_msg))
      }

      return(res)
    },

    #' Filter CLI Noise from LLM Output
    #' @description
    #' Removes common CLI-injected headers, keychain warnings, or MCP status messages
    #' that can corrupt the generated model content.
    #' @param text String or Character Vector. Raw output from the CLI.
    #' @return Character vector of cleaned lines.
    filter_llm_noise = function(text) {
      if (length(text) == 0) {
        return(character(0))
      }

      # Ensure we have lines
      lines <- if (length(text) == 1) strsplit(text, "\n")[[1]] else text

      # Blacklist of known noise patterns
      # Includes Keychain warnings, MCP status, and internal CLI logs
      noise_patterns <- c(
        "Keychain initialization", "Require stack", "Using FileKeychain",
        "Loaded cached credentials", "\\[IDEClient\\] Directory mismatch",
        "Scheduling MCP", "Executing MCP", "MCP context",
        "Registering notification", "Server.*supports", "Received tool update",
        "Received prompt update", "Refreshed context", "MCP issues detected",
        "Run /mcp list"
      )

      # Combined regex for pattern matching
      pattern <- paste(noise_patterns, collapse = "|")

      # Filter lines that DO NOT match any noise pattern
      clean_lines <- lines[!grepl(pattern, lines)]

      return(clean_lines)
    },

    #' Call the LLM
    #' @param prompt String. The prompt to send.
    #' @param model String. Optional model override.
    #' @param cli_opts List. Named list of CLI options.
    #' @param ... Additional arguments.
    #' @return String. Cleaned response from the LLM.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      stop("Abstract Method: call() must be implemented by subclass.")
    },

    #' Validate CLI Options
    #' @param cli_opts List. Named list to validate.
    #' @return Invisible TRUE if valid.
    validate_cli_opts = function(cli_opts) {
      if (length(cli_opts) == 0 || length(self$supported_opts) == 0) {
        return(invisible(TRUE))
      }
      unknown <- setdiff(names(cli_opts), self$supported_opts)
      if (length(unknown) > 0) {
        msg <- sprintf(
          "[%s] Unrecognized CLI option(s): %s. Supported: %s",
          self$id, paste(unknown, collapse = ", "),
          paste(self$supported_opts, collapse = ", ")
        )
        if (self$validation_mode == "strict") stop(msg)
        warning(msg)
      }
      invisible(TRUE)
    },

    #' Format CLI Options
    #' @param cli_opts List. Named list to format.
    #' @return Character vector of CLI flags.
    format_cli_opts = function(cli_opts = list()) {
      if (length(cli_opts) == 0) {
        return(character(0))
      }
      self$validate_cli_opts(cli_opts)
      purrr::imap(cli_opts, function(val, key) {
        # Convert underscores to hyphens for CLI flags
        flag <- paste0("--", gsub("_", "-", key))
        # Boolean flags: if TRUE, return flag name only; if FALSE, return nothing
        if (is.logical(val)) {
          if (isTRUE(val)) {
            return(flag)
          }
          return(character(0))
        }
        # Multi-value flags: repeat the flag name for each value
        if (length(val) > 1) {
          # Return nested list and unlist later
          return(as.character(rbind(flag, val)))
        }
        # Standard key-value pairs
        return(c(flag, as.character(val)))
      }) |> unlist()
    }
  )
)


#' <!-- APAF Bioinformatics | driver.R | Approved | 2026-03-28 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        drivers_cli.R
# Author:      APAF Agentic Workflow
# Purpose:     CLI-Based Agent Drivers (Gemini, Ollama)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Gemini CLI Driver R6 Class
#'
#' @description
#' Driver for the 'gemini' CLI tool.
#'
#' @importFrom R6 R6Class
#' @export
GeminiCLIDriver <- R6::R6Class("GeminiCLIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field model String. Default model. Omit to use CLI default.
    model = NULL,

    #' Initialize GeminiCLIDriver
    #' @param id Unique identifier.
    #' @param model String. Optional model.
    #' @param validation_mode String. "warning" or "strict".
    initialize = function(id = "gemini_cli", model = "gemini-1.5-pro", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "google", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$model <- model
      self$supported_opts <- c(
        "model", "sandbox", "yolo", "approval_mode", "policy",
        "admin_policy", "allowed_mcp_server_names", "allowed_tools",
        "extensions", "resume", "include_directories", "screen_reader",
        "output_format", "raw_output", "accept_raw_output_risk", "debug"
      )
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param cli_opts List. Named list of CLI options.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model

      # Ensure model is in cli_opts if provided
      if (!is.null(target_model) && !"model" %in% names(cli_opts)) {
        cli_opts$model <- target_model
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "gemini_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Use exec_in_dir to support worktrees
      res <- self$exec_in_dir("gemini", args = c("-p", "-", formatted_opts), stdin = tmp_prompt, stdout = TRUE, stderr = TRUE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(trimws(cleaned))
    }
  )
)

#' Ollama Driver R6 Class
#'
#' @description
#' Driver for the 'ollama' CLI tool (local).
#'
#' @importFrom R6 R6Class
#' @export
OllamaDriver <- R6::R6Class("OllamaDriver",
  inherit = AgentDriver,
  public = list(
    #' @field model String. Default model.
    model = "llama3.2",

    #' Initialize OllamaDriver
    #' @param id Unique identifier.
    #' @param model String. Default model.
    #' @param validation_mode String. "warning" or "strict".
    initialize = function(id = "ollama", model = "llama3.2", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "ollama", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$model <- model
      self$supported_opts <- c(
        "num_ctx", "temperature", "top_p", "top_k",
        "repeat_penalty", "seed", "num_predict"
      )
    },

    #' Format CLI Options for Ollama
    #' @param cli_opts List.
    #' @return Character vector.
    format_cli_opts = function(cli_opts = list()) {
      if (length(cli_opts) == 0) {
        return(character(0))
      }
      self$validate_cli_opts(cli_opts)
      # Ollama uses: -p key=value (stackable)
      purrr::imap(cli_opts, function(val, key) {
        c("-p", paste0(key, "=", val))
      }) |> unlist()
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model
      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "ollama_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      res <- self$exec_in_dir("ollama", args = c("run", target_model, formatted_opts), stdin = tmp_prompt, stdout = TRUE, stderr = FALSE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(cleaned)
    }
  )
)

#' Claude CLI Driver R6 Class
#'
#' @description
#' Driver for the 'claude' CLI tool.
#'
#' @importFrom R6 R6Class
#' @export
ClaudeCodeDriver <- R6::R6Class("ClaudeCodeDriver",
  inherit = AgentDriver,
  public = list(
    #' @field model String. Default model.
    model = "claude-3-5-sonnet-latest",

    #' Initialize ClaudeCodeDriver
    #' @param id Unique identifier.
    #' @param model String. Default model.
    #' @param validation_mode String. "warning" or "strict".
    initialize = function(id = "claude_cli", model = "claude-3-5-sonnet-latest", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "anthropic", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$model <- model
      self$supported_opts <- c(
        "add_dir", "agent", "agents", "allowedTools", "append_system_prompt",
        "betas", "continue", "dangerously_skip_permissions", "debug",
        "disallowedTools", "fallback_model", "input_format", "json_schema",
        "max_budget_usd", "mcp_config", "model", "output_format",
        "permission_mode", "print", "system_prompt", "tools", "verbose"
      )
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model

      if (!is.null(target_model) && !"model" %in% names(cli_opts)) {
        cli_opts$model <- target_model
      }

      # Claude CLI usually needs --print for non-interactive
      if (!"print" %in% names(cli_opts)) {
        cli_opts$print <- TRUE
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "claude_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Use exec_in_dir to support worktrees
      res <- self$exec_in_dir("claude", args = formatted_opts, stdin = tmp_prompt, stdout = TRUE, stderr = TRUE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(cleaned)
    }
  )
)

#' Copilot CLI Driver R6 Class
#'
#' @description
#' Driver for the 'gh copilot' CLI tool.
#'
#' @importFrom R6 R6Class
#' @export
CopilotCLIDriver <- R6::R6Class("CopilotCLIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field type String. Use 'shell' or 'git'.
    type = "shell",

    #' Initialize CopilotCLIDriver
    #' @param id Unique identifier.
    #' @param type String. Default type ('shell').
    #' @param validation_mode String. "warning" or "strict".
    initialize = function(id = "copilot_cli", type = "shell", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "github", model_name = "copilot", validation_mode = validation_mode, working_dir = working_dir)
      self$type <- type
      self$supported_opts <- c(
        "add_dir", "allow_all_paths", "allow_all_tools", "allow_tool",
        "deny_tool", "model", "prompt", "resume", "screen_reader",
        "log_level", "no_custom_instructions"
      )
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param type String override.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, type = NULL, cli_opts = list(), ...) {
      target_type <- if (!is.null(type)) type else self$type

      # Copilot CLI often uses --prompt for non-interactive
      if (!"prompt" %in% names(cli_opts)) {
        cli_opts$prompt <- prompt
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      # Implementation: gh copilot suggest -t <type> [opts]
      res <- self$exec_in_dir("gh", args = c("copilot", "suggest", "-t", target_type, formatted_opts), stdout = TRUE, stderr = TRUE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(cleaned)
    }
  )
)

#' <!-- APAF Bioinformatics | drivers_cli.R | Approved | 2026-03-28 -->

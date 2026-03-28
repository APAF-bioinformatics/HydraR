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
    initialize = function(id = "gemini_cli", model = NULL) {
      super$initialize(id)
      self$model <- model
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, ...) {
      target_model <- if (!is.null(model)) model else self$model

      # Execution using a temporary file for the prompt
      # This is more robust for multi-line strings and avoids shell length limits.
      tmp_prompt <- tempfile(pattern = "gemini_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Construct CLI arguments
      model_arg <- if (!is.null(target_model)) c("--model", target_model) else NULL

      # Execute CLI call: gemini --model <model> --file <temp_file>
      res <- system2("gemini", args = c(model_arg, "--file", shQuote(tmp_prompt)), stdout = TRUE, stderr = TRUE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(cleaned)
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
    initialize = function(id = "ollama", model = "llama3.2") {
      super$initialize(id)
      self$model <- model
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, ...) {
      target_model <- if (!is.null(model)) model else self$model

      # Implementation: ollama run <model> "<prompt>"
      # For ollama, it's often better to pipe the prompt or use the API if possible,
      # but the task specifies CLI drivers.

      tmp_prompt <- tempfile(pattern = "ollama_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      res <- system2("ollama", args = c("run", target_model), stdin = tmp_prompt, stdout = TRUE, stderr = FALSE)

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
    initialize = function(id = "claude_cli", model = "claude-3-5-sonnet-latest") {
      super$initialize(id)
      self$model <- model
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param model String override.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, ...) {
      target_model <- if (!is.null(model)) model else self$model

      # Implementation: claude "<prompt>"
      # Assuming the 'claude' CLI takes the prompt as an argument or stdin.
      # Using stdin for better handling of multi-line prompts.

      tmp_prompt <- tempfile(pattern = "claude_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Using system2 with stdin
      res <- system2("claude", args = character(), stdin = tmp_prompt, stdout = TRUE, stderr = TRUE)

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
    initialize = function(id = "copilot_cli", type = "shell") {
      super$initialize(id)
      self$type <- type
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param type String override.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, type = NULL, ...) {
      target_type <- if (!is.null(type)) type else self$type

      # Implementation: gh copilot suggest -t <type> "<prompt>"
      # Note: gh copilot returns interactive suggestions.
      # We use it for one-shot by grabbing the stdout.

      res <- system2("gh", args = c("copilot", "suggest", "-t", target_type, prompt), stdout = TRUE, stderr = TRUE)

      if (length(res) == 0) {
        return("")
      }

      cleaned <- paste(res, collapse = "\n")
      return(cleaned)
    }
  )
)

#' <!-- APAF Bioinformatics | drivers_cli.R | Approved | 2026-03-28 -->

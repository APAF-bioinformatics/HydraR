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

    #' @description Initialize GeminiCLIDriver
    #' @param id Unique identifier.
    #' @param model String. Optional model.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to isolated Git worktree.
    #' @param repo_root String. Path to the main repository root.
    initialize = function(id = "gemini_cli", model = "gemini-2.5-flash", validation_mode = "warning", working_dir = NULL, repo_root = NULL) {
      super$initialize(id, provider = "google", model_name = model, validation_mode = validation_mode, working_dir = working_dir, repo_root = repo_root)
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List. Named list of CLI options.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model
      if (!is.null(target_model)) {
        self$validate_no_injection(target_model)
      }

      # Standard fallback: prepend system_prompt to prompt if not natively supported by CLI
      final_prompt <- if (!is.null(system_prompt)) {
        sprintf("System Guidelines:\n%s\n\nUser Task:\n%s", system_prompt, prompt)
      } else {
        prompt
      }

      # Ensure model is in cli_opts if provided
      if (!is.null(target_model) && !"model" %in% names(cli_opts)) {
        cli_opts$model <- target_model
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "gemini_prompt_", fileext = ".txt")
      writeLines(final_prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      tmp_stdout <- tempfile(pattern = "gemini_stdout_", fileext = ".txt")
      tmp_stderr <- tempfile(pattern = "gemini_stderr_", fileext = ".txt")
      on.exit(unlink(c(tmp_stdout, tmp_stderr)), add = TRUE)

      # Path Retrieval: check env var then option
      cmd <- Sys.getenv("HYDRAR_GEMINI_PATH", unset = getOption("HydraR.gemini_path", "gemini"))

      # Root-Locked Execution Strategy
      exec_dir <- if (!is.null(self$repo_root)) self$repo_root else self$working_dir

      # Add worktree to context if we are running from root
      if (!is.null(self$repo_root) && !is.null(self$working_dir) && (self$repo_root != self$working_dir)) {
        cli_opts$include_directories <- unique(c(cli_opts$include_directories, self$working_dir))
        formatted_opts <- self$format_cli_opts(cli_opts)
      }

      # Use system2 with explicit stdout/stderr files to avoid interleaving and capture status
      gemini_args <- c("-p", "-", formatted_opts)
      gemini_args <- shQuote(gemini_args)
      exit_code <- if (!is.null(exec_dir)) {
        withr::with_dir(exec_dir, {
          system2(cmd, args = gemini_args, stdin = tmp_prompt, stdout = tmp_stdout, stderr = tmp_stderr)
        })
      } else {
        system2(cmd, args = gemini_args, stdin = tmp_prompt, stdout = tmp_stdout, stderr = tmp_stderr)
      }

      # Read results
      out_lines <- if (file.exists(tmp_stdout)) readLines(tmp_stdout, warn = FALSE) else character(0)
      err_lines <- if (file.exists(tmp_stderr)) readLines(tmp_stderr, warn = FALSE) else character(0)

      # Handle failure
      if (exit_code != 0) {
        err_msg <- paste(err_lines, collapse = "\n")
        stop(sprintf("[gemini_cli] CLI execution failed (exit code %d): %s", exit_code, substr(err_msg, 1, 1000)))
      }

      # Sanitize output from CLI noise (Keychain, MCP, etc.)
      clean_lines <- self$filter_llm_noise(out_lines)

      if (length(clean_lines) == 0) {
        return("")
      }

      cleaned_text <- paste(clean_lines, collapse = "\n")
      # Use HydraR utility to strip markdown fences if present
      return(extract_r_code_advanced(trimws(cleaned_text)))
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

    #' @description Initialize OllamaDriver
    #' @param id Unique identifier.
    #' @param model String. Default model.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to isolated Git worktree.
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model
      if (!is.null(target_model)) {
        self$validate_no_injection(target_model)
      }

      # Standard fallback: prepend system_prompt to prompt if not natively supported by CLI
      final_prompt <- if (!is.null(system_prompt)) {
        sprintf("System Guidelines:\n%s\n\nUser Task:\n%s", system_prompt, prompt)
      } else {
        prompt
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "ollama_prompt_", fileext = ".txt")
      writeLines(final_prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Respect global path option
      cmd <- getOption("HydraR.ollama_path", "ollama")

      res <- self$exec_in_dir(cmd, args = c("run", target_model, formatted_opts), stdin = tmp_prompt, stdout = TRUE, stderr = FALSE)

      # Sanitize output from CLI noise
      clean_lines <- self$filter_llm_noise(res)

      if (length(clean_lines) == 0) {
        return("")
      }

      cleaned <- paste(clean_lines, collapse = "\n")
      return(extract_r_code_advanced(cleaned))
    }
  )
)

#' Anthropic CLI Driver
#'
#' @description
#' Driver for the Anthropic `claude` (Claude Code) CLI.
#'
#' @export
AnthropicCLIDriver <- R6::R6Class(
  "AnthropicCLIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field model String. Default model.
    model = "sonnet",

    #' @description Initialize AnthropicCLIDriver
    #' @param id Unique identifier.
    #' @param model String. Default model.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to isolated Git worktree.
    #' @return A new `AnthropicCLIDriver` object.
    initialize = function(id = "claude_cli", model = "sonnet", validation_mode = "warning", working_dir = NULL) {
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$model
      if (!is.null(target_model)) {
        self$validate_no_injection(target_model)
      }

      if (!is.null(target_model) && !"model" %in% names(cli_opts)) {
        cli_opts$model <- target_model
      }

      if (!is.null(system_prompt)) {
        cli_opts$system_prompt <- system_prompt
      }

      # Claude CLI usually needs --print for non-interactive
      if (!"print" %in% names(cli_opts)) {
        cli_opts$print <- TRUE
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      tmp_prompt <- tempfile(pattern = "claude_prompt_", fileext = ".txt")
      writeLines(prompt, tmp_prompt)
      on.exit(unlink(tmp_prompt))

      # Respect global path option
      cmd <- getOption("HydraR.claude_path", "claude")

      # Use exec_in_dir to support worktrees
      res <- self$exec_in_dir(cmd, args = formatted_opts, stdin = tmp_prompt, stdout = TRUE, stderr = TRUE)

      # Sanitize output from CLI noise
      clean_lines <- self$filter_llm_noise(res)

      if (length(clean_lines) == 0) {
        return("")
      }

      cleaned <- paste(clean_lines, collapse = "\n")
      return(extract_r_code_advanced(cleaned))
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
    #' @description Initialize CopilotCLIDriver
    #' @param id Unique identifier.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to isolated Git worktree.
    initialize = function(id = "copilot_cli", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "github", model_name = "copilot", validation_mode = validation_mode, working_dir = working_dir)
      self$supported_opts <- c(
        "add_dir", "allow_all_paths", "allow_all_tools", "allow_tool",
        "deny_tool", "model", "prompt", "resume", "screen_reader",
        "log_level", "no_custom_instructions"
      )
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, system_prompt = NULL, cli_opts = list(), ...) {
      # Standard fallback: prepend system_prompt to prompt if not natively supported by CLI
      final_prompt <- if (!is.null(system_prompt)) {
        sprintf("System Guidelines:\n%s\n\nUser Task:\n%s", system_prompt, prompt)
      } else {
        prompt
      }

      # Modern gh copilot uses -p or --prompt for non-interactive
      if (!"prompt" %in% names(cli_opts)) {
        cli_opts$prompt <- final_prompt
      }

      # Non-interactive flags for agent use
      if (!"allow_all_tools" %in% names(cli_opts)) {
        cli_opts$allow_all_tools <- TRUE
      }
      if (!"no_custom_instructions" %in% names(cli_opts)) {
        cli_opts$no_custom_instructions <- TRUE
      }

      formatted_opts <- self$format_cli_opts(cli_opts)

      # Implementation: gh copilot -- -p <prompt> [opts]
      # Using -- to ensure sub-binary doesn't conflict with gh flags
      res <- self$exec_in_dir("gh", args = c("copilot", "--", formatted_opts), stdout = TRUE, stderr = TRUE)

      # Sanitize output from CLI noise
      clean_lines <- self$filter_llm_noise(res)

      if (length(clean_lines) == 0) {
        return("")
      }

      cleaned <- paste(clean_lines, collapse = "\n")
      return(extract_r_code_advanced(cleaned))
    }
  )
)

#' OpenAI Codex CLI Driver
#'
#' Supports the official `codex` CLI (v0.118+).
#'
#' @export
OpenAICodexCLIDriver <- R6::R6Class(
  "OpenAICodexCLIDriver",
  inherit = AgentDriver,
  public = list(
    #' @description Initialize OpenAICodexCLIDriver
    #' @param id String. Unique identifier.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to isolated Git worktree.
    initialize = function(id = "codex_cli", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "openai", model_name = "codex", validation_mode = validation_mode, working_dir = working_dir)
      self$supported_opts <- c("model", "sandbox", "cd", "search", "add_dir", "ephemeral", "color")
    },

    #' Call the LLM
    #' @param prompt String.
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List.
    #' @param ... Additional arguments.
    #' @return String. Cleaned result.
    call = function(prompt, system_prompt = NULL, cli_opts = list(), ...) {
      final_prompt <- if (!is.null(system_prompt)) {
        sprintf("System Guidelines:\n%s\n\nUser Task:\n%s", system_prompt, prompt)
      } else {
        prompt
      }

      # Always use --json for reliable parsing in agentic workflows
      cmd_args <- c("exec", "--json")

      # Convert cli_opts to flags (kabab-case)
      for (opt in names(cli_opts)) {
        val <- cli_opts[[opt]]
        flag <- gsub("_", "-", opt)
        if (is.logical(val)) {
          if (val) cmd_args <- c(cmd_args, sprintf("--%s", flag))
        } else {
          cmd_args <- c(cmd_args, sprintf("--%s", flag), as.character(val))
        }
      }

      # Append prompt
      cmd_args <- c(cmd_args, final_prompt)

      # Execution using the worktree-aware helper
      res <- self$exec_in_dir("codex", args = cmd_args, stdout = TRUE, stderr = TRUE)

      # JSONL Stream Parsing Logic
      # We look for the 'item.completed' event where item$type == 'agent_message'
      final_content <- ""
      for (line in res) {
        if (trimws(line) == "") next
        if (!startsWith(line, "{")) next # Skip non-json preamble if any

        parsed <- tryCatch(jsonlite::fromJSON(line), error = function(e) NULL)
        if (is.null(parsed)) next

        if (!is.null(parsed$type) && parsed$type == "item.completed") {
          item <- parsed$item
          if (!is.null(item) && !is.null(item$type) && item$type == "agent_message") {
            final_content <- item$text
          }
        }
      }

      # Final fallback: If JSON parsing failed to find a message, try raw text filtering
      if (nchar(final_content) == 0) {
        clean_lines <- self$filter_llm_noise(res)
        final_content <- paste(clean_lines, collapse = "\n")
      }

      return(final_content)
    }
  )
)

#' <!-- APAF Bioinformatics | drivers_cli.R | Approved | 2026-04-03 -->

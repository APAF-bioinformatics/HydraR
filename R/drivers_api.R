# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        drivers_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Cloud API Drivers (OpenAI, Anthropic, Gemini)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' OpenAI API Driver R6 Class
#'
#' @description Driver for OpenAI Chat Completions API.
#' @return An `OpenAIDriver` R6 object.
#' @export
OpenAIDriver <- R6::R6Class("OpenAIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field api_url String. Base URL.
    api_url = "https://api.openai.com/v1/chat/completions",

    #' Initialize OpenAIDriver
    #' @param id String. Unique identifier.
    #' @param model String. Model name.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to worktree.
    #' @return A new `OpenAIDriver` object.
    initialize = function(id = "openai_api", model = "gpt-4o", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "openai", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$supported_opts <- c("temperature", "max_tokens", "top_p", "frequency_penalty", "presence_penalty", "response_format")
    },

    #' Get Capabilities
    #' @return A list of capabilities.
    get_capabilities = function() {
      list(streaming = TRUE, json_mode = TRUE, tools = TRUE)
    },

    #' Call OpenAI API
    #' @param prompt String. The prompt text.
    #' @param model String. Optional model override.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for OpenAIDriver. Install it with install.packages('httr2').")
      }

      # Execute within worktree context if assigned
      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("OPENAI_API_KEY")
        if (api_key == "") stop("OPENAI_API_KEY environment variable not set.")

        req <- httr2::request(self$api_url) |>
          httr2::req_auth_bearer_token(api_key) |>
          httr2::req_body_json(utils::modifyList(list(
            model = target_model,
            messages = list(list(role = "user", content = prompt))
          ), cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- httr2::req_perform(req)
        cont <- httr2::resp_body_json(resp)

        return(extract_r_code_advanced(cont$choices[[1]]$message$content))
      })
    }
  )
)

#' Anthropic API Driver R6 Class
#'
#' @description Driver for Anthropic Messages API.
#' @return An `AnthropicDriver` R6 object.
#' @export
AnthropicDriver <- R6::R6Class("AnthropicDriver",
  inherit = AgentDriver,
  public = list(
    #' @field api_url String. Base URL.
    api_url = "https://api.anthropic.com/v1/messages",

    #' Initialize AnthropicDriver
    #' @param id String. Unique identifier.
    #' @param model String. Model name.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to worktree.
    #' @return A new `AnthropicDriver` object.
    initialize = function(id = "anthropic_api", model = "claude-3-5-sonnet-20241022", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "anthropic", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$supported_opts <- c("max_tokens", "metadata", "stop_sequences", "system", "temperature", "top_k", "top_p")
    },

    #' Get Capabilities
    #' @return A list of capabilities.
    get_capabilities = function() {
      list(streaming = TRUE, json_mode = TRUE, tools = TRUE)
    },

    #' Call Anthropic API
    #' @param prompt String. The prompt text.
    #' @param model String. Optional model override.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for AnthropicDriver.")
      }

      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("ANTHROPIC_API_KEY")
        if (api_key == "") stop("ANTHROPIC_API_KEY environment variable not set.")

        # Anthropic requires max_tokens as mandatory
        if (!"max_tokens" %in% names(cli_opts)) cli_opts$max_tokens <- 4096

        req <- httr2::request(self$api_url) |>
          httr2::req_headers(
            "x-api-key" = api_key,
            "anthropic-version" = "2023-06-01"
          ) |>
          httr2::req_body_json(utils::modifyList(list(
            model = target_model,
            messages = list(list(role = "user", content = prompt))
          ), cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- httr2::req_perform(req)
        cont <- httr2::resp_body_json(resp)

        return(extract_r_code_advanced(cont$content[[1]]$text))
      })
    }
  )
)

#' Gemini API Driver R6 Class
#'
#' @description Driver for Google Gemini (AI Studio) API.
#' @return A `GeminiAPIDriver` R6 object.
#' @export
GeminiAPIDriver <- R6::R6Class("GeminiAPIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field api_base String. Base URL.
    api_base = "https://generativelanguage.googleapis.com/v1beta",

    #' Initialize GeminiAPIDriver
    #' @param id String. Unique identifier.
    #' @param model String. Model name.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to worktree.
    #' @return A new `GeminiAPIDriver` object.
    initialize = function(id = "gemini_api", model = "gemini-1.5-pro", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, provider = "google", model_name = model, validation_mode = validation_mode, working_dir = working_dir)
      self$supported_opts <- c("generationConfig", "safetySettings", "systemInstruction", "tools")
    },

    #' Get Capabilities
    #' @return A list of capabilities.
    get_capabilities = function() {
      list(streaming = TRUE, json_mode = TRUE, tools = TRUE)
    },

    #' Call Gemini API
    #' @param prompt String. The prompt text.
    #' @param model String. Optional model override.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for GeminiAPIDriver.")
      }

      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("GOOGLE_API_KEY")
        if (api_key == "") stop("GOOGLE_API_KEY environment variable not set.")

        url <- sprintf("%s/models/%s:generateContent", self$api_base, target_model)

        req <- httr2::request(url) |>
          httr2::req_url_query(key = api_key) |>
          httr2::req_body_json(utils::modifyList(list(
            contents = list(list(parts = list(list(text = prompt))))
          ), cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- httr2::req_perform(req)
        cont <- httr2::resp_body_json(resp)

        return(extract_r_code_advanced(cont$candidates[[1]]$content$parts[[1]]$text))
      })
    }
  )
)

# <!-- APAF Bioinformatics | drivers_api.R | Approved | 2026-03-29 -->

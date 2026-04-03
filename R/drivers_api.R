# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        drivers_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Cloud API Drivers (OpenAI, Anthropic, Gemini)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' OpenAI API Driver
#'
#' @description
#' Implementation of the OpenAI Chat Completions API.
#'
#' @export
OpenAIAPIDriver <- R6::R6Class(
  "OpenAIAPIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field api_url String. Base URL.
    api_url = "https://api.openai.com/v1/chat/completions",

    #' Initialize OpenAIAPIDriver
    #' @param id String. Unique identifier.
    #' @param model String. Model name.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to worktree.
    #' @return A new `OpenAIAPIDriver` object.
    initialize = function(id = "openai_api", model = "gpt-5.4-mini", validation_mode = "warning", working_dir = NULL) {
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for OpenAIAPIDriver. Install it with install.packages('httr2').")
      }

      # Execute within worktree context if assigned
      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("OPENAI_API_KEY")
        if (api_key == "") stop("OPENAI_API_KEY environment variable not set.")

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message("DEBUG: [", self$id, "] Calling URL: ", self$api_url)
        }

        messages <- list(list(role = "user", content = prompt))
        if (!is.null(system_prompt)) {
          messages <- c(list(list(role = "system", content = system_prompt)), messages)
        }

        req <- httr2::request(self$api_url) |>
          httr2::req_auth_bearer_token(api_key) |>
          httr2::req_body_json(utils::modifyList(list(
            model = target_model,
            messages = messages
          ), cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- tryCatch(
          {
            httr2::req_perform(req)
          },
          error = function(e) {
            if (!is.null(e$resp)) {
              body_text <- tryCatch(httr2::resp_body_string(e$resp), error = function(ee) "unreadable body")
              stop(sprintf(
                "[%s] OpenAI API request failed: %s. Body: %s",
                self$id, httr2::resp_status_desc(e$resp), body_text
              ))
            }
            stop(sprintf("[%s] OpenAI API request failed: %s", self$id, e$message))
          }
        )
        cont <- httr2::resp_body_json(resp)

        if (is.null(cont$choices) || length(cont$choices) == 0) {
          stop(sprintf("[%s] OpenAI API returned success but no choices: %s", self$id, jsonlite::toJSON(cont)))
        }

        return(extract_r_code_advanced(cont$choices[[1]]$message$content))
      })
    }
  )
)

#' Anthropic API Driver
#'
#' @description
#' Implementation of the Anthropic Messages API.
#'
#' @export
AnthropicAPIDriver <- R6::R6Class(
  "AnthropicAPIDriver",
  inherit = AgentDriver,
  public = list(
    #' @field api_url String. Base URL.
    api_url = "https://api.anthropic.com/v1/messages",

    #' Initialize AnthropicAPIDriver
    #' @param id String. Unique identifier.
    #' @param model String. Model name.
    #' @param validation_mode String. "warning" or "strict".
    #' @param working_dir String. Optional. Path to worktree.
    #' @return A new `AnthropicAPIDriver` object.
    initialize = function(id = "anthropic_api", model = "claude-sonnet-4-6", validation_mode = "warning", working_dir = NULL) {
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for AnthropicAPIDriver.")
      }

      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("ANTHROPIC_API_KEY")
        if (api_key == "") stop("ANTHROPIC_API_KEY environment variable not set.")

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message("DEBUG: [", self$id, "] Calling URL: ", self$api_url)
        }

        # Anthropic requires max_tokens as mandatory
        if (!"max_tokens" %in% names(cli_opts)) cli_opts$max_tokens <- 4096

        req_body <- list(
          model = target_model,
          messages = list(list(role = "user", content = prompt))
        )
        if (!is.null(system_prompt)) {
          req_body$system <- system_prompt
        }

        req <- httr2::request(self$api_url) |>
          httr2::req_headers(
            "x-api-key" = api_key,
            "anthropic-version" = "2023-06-01"
          ) |>
          httr2::req_body_json(utils::modifyList(req_body, cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- tryCatch(
          {
            httr2::req_perform(req)
          },
          error = function(e) {
            if (!is.null(e$resp)) {
              body_text <- tryCatch(httr2::resp_body_string(e$resp), error = function(ee) "unreadable body")
              stop(sprintf(
                "[%s] Anthropic API request failed: %s. Body: %s",
                self$id, httr2::resp_status_desc(e$resp), body_text
              ))
            }
            stop(sprintf("[%s] Anthropic API request failed: %s", self$id, e$message))
          }
        )
        cont <- httr2::resp_body_json(resp)

        if (is.null(cont$content) || length(cont$content) == 0) {
          stop(sprintf("[%s] Anthropic API returned success but no content: %s", self$id, jsonlite::toJSON(cont)))
        }

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
    initialize = function(id = "gemini_api", model = "gemini-3.1-flash-lite-preview", validation_mode = "warning", working_dir = NULL) {
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
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List. Additional API options.
    #' @param ... Additional arguments.
    #' @return String. LLM response.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) {
        stop("Package 'httr2' is required for GeminiAPIDriver.")
      }

      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr

      handler(self$working_dir, {
        target_model <- if (!is.null(model)) model else self$model_name
        api_key <- Sys.getenv("GOOGLE_API_KEY")
        if (api_key == "") stop("GOOGLE_API_KEY environment variable not set.")

        url <- sprintf("%s/models/%s:generateContent", self$api_base, target_model)
        message("DEBUG: [", self$id, "] Calling URL: ", url)

        req_body <- list(
          contents = list(list(parts = list(list(text = prompt))))
        )
        if (!is.null(system_prompt)) {
          req_body$systemInstruction <- list(parts = list(list(text = system_prompt)))
        }

        req <- httr2::request(url) |>
          httr2::req_url_query(key = api_key) |>
          httr2::req_body_json(utils::modifyList(req_body, cli_opts)) |>
          httr2::req_retry(max_tries = 3)

        resp <- tryCatch(
          {
            httr2::req_perform(req)
          },
          error = function(e) {
            if (!is.null(e$resp)) {
              body_text <- tryCatch(httr2::resp_body_string(e$resp), error = function(ee) "unreadable body")
              stop(sprintf(
                "[%s] Gemini API request failed: %s. Body: %s",
                self$id, httr2::resp_status_desc(e$resp), body_text
              ))
            }
            stop(sprintf("[%s] Gemini API request failed: %s", self$id, e$message))
          }
        )
        cont <- httr2::resp_body_json(resp)

        return(extract_r_code_advanced(cont$candidates[[1]]$content$parts[[1]]$text))
      })
    }
  )
)

# String. Default "gemini-3.1-flash-image-preview".

#' Gemini Image API Driver R6 Class
#'
#' @description Driver for Google Gemini's multimodal image generation (2026 models).
#' @return A `GeminiImageDriver` R6 object.
#' @export
GeminiImageDriver <- R6::R6Class("GeminiImageDriver",
  inherit = GeminiAPIDriver,
  public = list(
    #' @field output_dir String. Directory to save generated images.
    output_dir = "images",
    #' @field aspect_ratio String. Default "16:9".
    aspect_ratio = "16:9",

    #' Initialize GeminiImageDriver
    #' @param id String.
    #' @param model String. Default "imagen-3.0-generate-001".
    #' @param output_dir String.
    #' @param aspect_ratio String.
    #' @param validation_mode String.
    #' @param working_dir String.
    initialize = function(id = "gemini_image", model = "gemini-3.1-flash-image-preview", output_dir = "images", aspect_ratio = "1:1", validation_mode = "warning", working_dir = NULL) {
      super$initialize(id, model = model, validation_mode = validation_mode, working_dir = working_dir)
      self$output_dir <- output_dir
      self$aspect_ratio <- aspect_ratio
      self$supported_opts <- c(self$supported_opts, "aspectRatio", "imageSize", "sampleCount")
    },

    #' Call Gemini Image API (Multimodal Unified)
    #' @param prompt String. Image prompt.
    #' @param model String. Optional override.
    #' @param system_prompt String. Optional system prompt.
    #' @param cli_opts List. Parameters (aspectRatio, etc).
    #' @param ... Additional arguments.
    #' @return String. Local path to the generated image.
    call = function(prompt, model = NULL, system_prompt = NULL, cli_opts = list(), ...) {
      if (!requireNamespace("httr2", quietly = TRUE)) stop("Package 'httr2' is required.")

      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr
      handler(self$working_dir, {
        target_model <- model %||% self$model_name
        api_key <- Sys.getenv("GOOGLE_API_KEY")
        if (api_key == "") stop("GOOGLE_API_KEY environment variable not set.")

        # Ensure output directory exists
        if (!dir.exists(self$output_dir)) dir.create(self$output_dir, recursive = TRUE)

        # Determine if we use GenerateContent (Gemini 3.x) or Predict (Imagen)
        is_imagen <- grepl("^imagen-", target_model)

        if (is_imagen) {
          url <- sprintf("%s/models/%s:predict", self$api_base, target_model)
        } else {
          url <- sprintf("%s/models/%s:generateContent", self$api_base, target_model)
        }

        # Build request body based on model type
        if (is_imagen) {
          # Imagen requires parameters in snake_case (2026 schema)
          final_params <- list(
            aspect_ratio = cli_opts$aspectRatio %||% self$aspect_ratio,
            sampleCount = as.integer(cli_opts$sampleCount %||% 1)
          )
          # Note: personGeneration is often restricted in 2026, so only add if explicitly requested
          if (!is.null(cli_opts$personGeneration)) {
            final_params$person_generation <- cli_opts$personGeneration
          }

          request_body <- list(
            instances = list(list(prompt = prompt)),
            parameters = final_params
          )
        } else {
          # Gemini 3.x Native Multimodal Output (generateContent)
          # Note: aspectRatio is NOT supported in generateContent generationConfig.
          # The model infers dimensions from the prompt. Use prompt engineering
          # (e.g. "wide landscape format") to influence aspect ratio.
          request_body <- list(
            contents = list(
              list(parts = list(list(text = prompt)))
            ),
            generationConfig = list(
              responseModalities = list("IMAGE")
            )
          )
          if (!is.null(system_prompt)) {
            request_body$systemInstruction <- list(parts = list(list(text = system_prompt)))
          }
        }

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message(sprintf(
            "DEBUG: [%s] Calling Gemini %s API for model: %s",
            self$id, ifelse(is_imagen, "Predict", "GenerateContent"), target_model
          ))
          message(sprintf("DEBUG: [%s] Prompt: %s...", self$id, substr(prompt, 1, 50)))
        }

        # Use curl::curl_fetch_disk to avoid httr2 crash on large responses
        # and system2() hangs in R6/withr context.
        req_body_json <- jsonlite::toJSON(request_body, auto_unbox = TRUE)
        resp_file <- tempfile(pattern = "gemini_resp_", fileext = ".json")
        call_url <- sprintf("%s?key=%s", url, api_key)

        h <- curl::new_handle()
        curl::handle_setopt(h,
          customrequest = "POST",
          postfields = as.character(req_body_json),
          timeout = 120
        )
        curl::handle_setheaders(h, "Content-Type" = "application/json")

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message("DEBUG: [", self$id, "] curl_fetch_disk to ", resp_file, "...")
        }
        result <- curl::curl_fetch_disk(call_url, path = resp_file, handle = h)
        status <- result$status_code

        if (status != 200) {
          err_body <- if (file.exists(resp_file)) paste(readLines(resp_file, warn = FALSE), collapse = "\n") else "Unknown"
          stop(sprintf("[%s] Gemini API failed: HTTP %s. Body: %s", self$id, status, err_body))
        }

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message("DEBUG: [", self$id, "] Response saved (", file.size(resp_file), " bytes). Parsing JSON...")
        }
        cont <- jsonlite::fromJSON(resp_file, simplifyVector = FALSE)

        # Cleanup
        unlink(resp_file)

        # Extract base64 image data based on format
        img_b64 <- NULL
        mime_type <- "image/png"

        if (is_imagen) {
          # Imagen Predict format
          if (!is.null(cont$predictions) && length(cont$predictions) > 0) {
            img_b64 <- cont$predictions[[1]]$bytesBase64Encoded
            mime_type <- cont$predictions[[1]]$mimeType %||% "image/png"
          }
        } else {
          # Gemini 3.x generateContent format (inlineData)
          if (!is.null(cont$candidates) && length(cont$candidates) > 0) {
            parts <- cont$candidates[[1]]$content$parts
            img_part <- purrr::detect(parts, function(p) !is.null(p$inlineData$data))
            if (!is.null(img_part)) {
              img_b64 <- img_part$inlineData$data
              mime_type <- img_part$inlineData$mimeType %||% "image/jpeg"
            }
          }
        }

        if (is.null(img_b64) || img_b64 == "") {
          stop(sprintf(
            "[%s] No image data found in %s response from model %s.",
            self$id, ifelse(is_imagen, "predict", "generateContent"), target_model
          ))
        }

        # Save and return path
        ext <- if (grepl("jpeg|jpg", mime_type)) ".jpg" else ".png"
        filename <- cli_opts[["filename"]] %||% paste0(digest::digest(prompt, algo = "md5"), ext)
        final_path <- file.path(self$output_dir, filename)

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") message("DEBUG: [", self$id, "] Decoding base64...")
        bin_data <- base64enc::base64decode(img_b64)
        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") message("DEBUG: [", self$id, "] Writing ", length(bin_data), " bytes to ", final_path)
        writeBin(bin_data, final_path)

        if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
          message(sprintf("[%s] Successfully saved Gemini-generated image: %s", self$id, final_path))
        }
        return(final_path)
      })
    }
  )
)

# <!-- APAF Bioinformatics | drivers_api.R | Approved | 2026-03-29 -->

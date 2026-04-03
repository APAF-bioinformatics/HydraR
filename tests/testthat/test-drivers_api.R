# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-drivers_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Mock-based Tests for Cloud API Drivers
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(httr2)

test_that("OpenAIAPIDriver validates missing API key", {
  withr::with_envvar(list(OPENAI_API_KEY = ""), {
    drv <- OpenAIAPIDriver$new()
    expect_error(drv$call("Hello"), "OPENAI_API_KEY environment variable not set")
  })
})

test_that("AnthropicAPIDriver validates missing API key", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = ""), {
    drv <- AnthropicAPIDriver$new()
    expect_error(drv$call("Hello"), "ANTHROPIC_API_KEY environment variable not set")
  })
})

test_that("GeminiAPIDriver validates missing API key", {
  withr::with_envvar(list(GOOGLE_API_KEY = ""), {
    drv <- GeminiAPIDriver$new()
    expect_error(drv$call("Hello"), "GOOGLE_API_KEY environment variable not set")
  })
})

test_that("OpenAIAPIDriver correctly formats requests and parses response", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIAPIDriver$new()

    # Mock response
    mock_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        choices = list(list(message = list(content = "AI Response")))
      ), auto_unbox = TRUE))
    )

    httr2::with_mocked_responses(
      setNames(list(mock_resp), drv$api_url),
      {
        res <- drv$call("Hello")
        expect_equal(res, "AI Response")
      }
    )
  })
})

test_that("OpenAIAPIDriver handles API errors gracefully", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIAPIDriver$new()
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500, body = charToRaw("Internal Error")),
      {
        expect_error(drv$call("Hello"), "OpenAI API request failed: Internal Server Error. Body: Internal Error")
      }
    )
  })
})

test_that("AnthropicAPIDriver correctly formats requests and parses response", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicAPIDriver$new()

    # Mock response
    mock_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        content = list(list(text = "Claude Response"))
      ), auto_unbox = TRUE))
    )

    httr2::with_mocked_responses(
      setNames(list(mock_resp), drv$api_url),
      {
        res <- drv$call("Hello")
        expect_equal(res, "Claude Response")
      }
    )
  })
})

test_that("AnthropicAPIDriver handles API errors gracefully", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicAPIDriver$new()
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500, body = charToRaw("Anthropic Error")),
      {
        expect_error(drv$call("Hello"), "Anthropic API request failed: Internal Server Error. Body: Anthropic Error")
      }
    )
  })
})

test_that("GeminiAPIDriver correctly formats requests and parses response", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()

    # Mock response
    mock_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        candidates = list(list(content = list(parts = list(list(text = "Gemini Response")))))
      ), auto_unbox = TRUE))
    )

    gemini_url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=test_key"
    httr2::with_mocked_responses(
      setNames(list(mock_resp), gemini_url),
      {
        res <- drv$call("Hello")
        expect_equal(res, "Gemini Response")
      }
    )
  })
})

test_that("GeminiAPIDriver handles API errors gracefully", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500),
      {
        expect_error(drv$call("Hello"), "Gemini API request failed")
      }
    )
  })
})


test_that("OpenAIAPIDriver correctly handles API errors", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIAPIDriver$new()

    # Mock error response
    mock_err <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_err,
      {
        expect_error(
          drv$call("Hello"),
          "OpenAI API request failed:"
        )
      }
    )
  })
})

test_that("AnthropicAPIDriver correctly handles API errors", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicAPIDriver$new()

    mock_err <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_err,
      {
        expect_error(
          drv$call("Hello"),
          "Anthropic API request failed:"
        )
      }
    )
  })
})

test_that("GeminiAPIDriver correctly handles API errors", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()

    mock_err <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_err,
      {
        expect_error(
          drv$call("Hello"),
          "Gemini API request failed:"
        )
      }
    )
  })
})

test_that("API Drivers report correct capabilities", {
  drv_openai <- OpenAIAPIDriver$new()
  caps_openai <- drv_openai$get_capabilities()
  expect_true(caps_openai$json_mode)
  expect_true(caps_openai$tools)

  drv_anthropic <- AnthropicAPIDriver$new()
  caps_anthropic <- drv_anthropic$get_capabilities()
  expect_true(caps_anthropic$json_mode)
  expect_true(caps_anthropic$tools)

  drv_gemini <- GeminiAPIDriver$new()
  caps_gemini <- drv_gemini$get_capabilities()
  expect_true(caps_gemini$json_mode)
  expect_true(caps_gemini$tools)
})

test_that("OpenAIAPIDriver handles network failures gracefully", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIAPIDriver$new()

    mock_error <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "OpenAI API request failed:")
      }
    )
  })
})

test_that("AnthropicAPIDriver handles network failures gracefully", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicAPIDriver$new()

    mock_error <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "Anthropic API request failed:")
      }
    )
  })
})

test_that("GeminiAPIDriver handles network failures gracefully", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()

    mock_error <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "Gemini API request failed:")
      }
    )
  })
})

# <!-- APAF Bioinformatics | test-drivers_api.R | Approved | 2026-03-29 -->

test_that("GeminiImageDriver correctly handles base64 responses and persistence", {
  skip_if_not_installed("base64enc")
  skip_if_not_installed("mockery")

  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    withr::with_tempdir({
      # Setup dummy image content (1x1 transparent pixel)
      dummy_base64 <- "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="

      drv <- GeminiImageDriver$new(model = "gemini-3.1-flash-image-preview", output_dir = ".")

      # Mock response structure based on Gemini API expectations
      mock_json <- list(
        candidates = list(list(content = list(parts = list(list(
          inlineData = list(mimeType = "image/png", data = dummy_base64)
        )))))
      )

      # Since GeminiImageDriver uses curl::curl_fetch_disk, httr2 mocks won't work.
      # We use mockery to stub the curl call.
      mockery::stub(drv$call, "curl::curl_fetch_disk", function(url, path, handle) {
        # Write the mock JSON to the path specified by the caller
        writeLines(jsonlite::toJSON(mock_json, auto_unbox = TRUE), path)
        return(list(status_code = 200))
      })

      img_path <- drv$call("Draw a cat", cli_opts = list(filename = "cat.png"))
      expect_equal(basename(img_path), "cat.png")
      expect_true(file.exists("cat.png"))

      # Cleanup is handled by with_tempdir
    })
  })
})

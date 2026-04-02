# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-drivers_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Mock-based Tests for Cloud API Drivers
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(httr2)

test_that("OpenAIDriver validates missing API key", {
  withr::with_envvar(list(OPENAI_API_KEY = ""), {
    drv <- OpenAIDriver$new()
    expect_error(drv$call("Hello"), "OPENAI_API_KEY environment variable not set")
  })
})

test_that("AnthropicDriver validates missing API key", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = ""), {
    drv <- AnthropicDriver$new()
    expect_error(drv$call("Hello"), "ANTHROPIC_API_KEY environment variable not set")
  })
})

test_that("GeminiAPIDriver validates missing API key", {
  withr::with_envvar(list(GOOGLE_API_KEY = ""), {
    drv <- GeminiAPIDriver$new()
    expect_error(drv$call("Hello"), "GOOGLE_API_KEY environment variable not set")
  })
})

test_that("OpenAIDriver correctly formats requests and parses response", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIDriver$new()

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

test_that("OpenAIDriver handles API errors gracefully", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIDriver$new()
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500),
      {
        expect_error(drv$call("Hello"), "OpenAI API request failed")
      }
    )
  })
})

test_that("AnthropicDriver correctly formats requests and parses response", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicDriver$new()

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

test_that("AnthropicDriver handles API errors gracefully", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicDriver$new()
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500),
      {
        expect_error(drv$call("Hello"), "Anthropic API request failed")
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


test_that("OpenAIDriver correctly handles API errors", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIDriver$new()

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

test_that("AnthropicDriver correctly handles API errors", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicDriver$new()

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
  drv_openai <- OpenAIDriver$new()
  caps_openai <- drv_openai$get_capabilities()
  expect_true(caps_openai$json_mode)
  expect_true(caps_openai$tools)

  drv_anthropic <- AnthropicDriver$new()
  caps_anthropic <- drv_anthropic$get_capabilities()
  expect_true(caps_anthropic$json_mode)
  expect_true(caps_anthropic$tools)

  drv_gemini <- GeminiAPIDriver$new()
  caps_gemini <- drv_gemini$get_capabilities()
  expect_true(caps_gemini$json_mode)
  expect_true(caps_gemini$tools)
})

test_that("OpenAIDriver handles network failures gracefully", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIDriver$new()

    mock_error <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "OpenAI API request failed: HTTP 500 Internal Server Error")
      }
    )
  })
})

test_that("AnthropicDriver handles network failures gracefully", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicDriver$new()

    mock_error <- function(req) {
      httr2::response(status_code = 500)
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "Anthropic API request failed: HTTP 500 Internal Server Error")
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
        expect_error(drv$call("Hello"), "Gemini API request failed: HTTP 500 Internal Server Error")
      }
    )
  })
})

# <!-- APAF Bioinformatics | test-drivers_api.R | Approved | 2026-03-29 -->

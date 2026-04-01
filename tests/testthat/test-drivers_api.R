# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-drivers_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Mock-based Tests for Cloud API Drivers
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(httr2)

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


test_that("API Drivers report correct capabilities", {
  drv <- OpenAIDriver$new()
  caps <- drv$get_capabilities()
  expect_true(caps$json_mode)
  expect_true(caps$tools)
})

test_that("OpenAIDriver handles network failures gracefully", {
  withr::with_envvar(list(OPENAI_API_KEY = "test_key"), {
    drv <- OpenAIDriver$new()

    mock_error <- function(req) {
      stop("Could not resolve host: api.openai.com")
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "OpenAI API request failed: Could not resolve host")
      }
    )
  })
})

test_that("AnthropicDriver handles network failures gracefully", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicDriver$new()

    mock_error <- function(req) {
      stop("Could not resolve host: api.anthropic.com")
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "Anthropic API request failed: Could not resolve host")
      }
    )
  })
})

test_that("GeminiAPIDriver handles network failures gracefully", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()

    mock_error <- function(req) {
      stop("Could not resolve host: generativelanguage.googleapis.com")
    }

    httr2::with_mocked_responses(
      mock_error,
      {
        expect_error(drv$call("Hello"), "Gemini API request failed: Could not resolve host")
      }
    )
  })
})

# <!-- APAF Bioinformatics | test-drivers_api.R | Approved | 2026-03-29 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-jules_api.R
# Author:      APAF Agentic Workflow
# Purpose:     Mock-based Tests for Jules API Client and Node
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(httr2)

test_that("JulesClient handles authentication and requests", {
  withr::with_envvar(list(JULES_API_KEY = "test_jules_key"), {
    client <- JulesClient$new()
    
    # Mock response for list_sources
    mock_sources_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        sources = list(list(name = "sources/github/owner/repo", id = "github/owner/repo"))
      ), auto_unbox = TRUE))
    )
    
    httr2::with_mocked_responses(
      list("https://jules.googleapis.com/v1alpha/sources" = mock_sources_resp),
      {
        res <- client$list_sources()
        expect_equal(res$sources[[1]]$id, "github/owner/repo")
      }
    )
  })
})

test_that("JulesClient create_session and get_session work", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_google_key"), {
    client <- JulesClient$new()
    
    # Mock response for create_session
    mock_create_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        name = "sessions/123",
        id = "123",
        title = "Boba App"
      ), auto_unbox = TRUE))
    )
    
    # Mock response for get_session
    mock_get_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        name = "sessions/123",
        id = "123",
        outputs = list(list(pullRequest = list(url = "https://github.com/owner/repo/pull/1")))
      ), auto_unbox = TRUE))
    )
    
    httr2::with_mocked_responses(
      list(
        "https://jules.googleapis.com/v1alpha/sessions" = mock_create_resp,
        "https://jules.googleapis.com/v1alpha/sessions/123" = mock_get_resp
      ),
      {
        session <- client$create_session(prompt = "Go", source = "sources/github/owner/repo")
        expect_equal(session$id, "123")
        
        details <- client$get_session("123")
        expect_equal(details$outputs[[1]]$pullRequest$url, "https://github.com/owner/repo/pull/1")
      }
    )
  })
})

test_that("AgentJulesNode correctly polls and returns result", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    # We'll mock the client methods or the HTTP responses
    # Mocking HTTP is safer for integration
    
    mock_create_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(id = "456"), auto_unbox = TRUE))
    )
    
    # First poll: no outputs
    mock_poll1_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(id = "456", outputs = list()), auto_unbox = TRUE))
    )
    
    # Second poll: success
    mock_poll2_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        id = "456", 
        outputs = list(list(pullRequest = list(url = "https://github.com/owner/repo/pull/2")))
      ), auto_unbox = TRUE))
    )
    
    # Setup node with short poll interval for testing
    node <- AgentJulesNode$new(
      id = "jules_test",
      prompt = "Fix bugs",
      source = "sources/github/owner/repo",
      branch = "main",
      timeout = 5
    )
    node$poll_interval <- 0.1 # Very fast for test
    
    # This is tricky because httr2::with_mocked_responses usually match 1:1 or cyclical
    # We can provide a list of responses to be used in order
    responses <- list(mock_create_resp, mock_poll1_resp, mock_poll2_resp)
    idx <- 0
    
    httr2::with_mocked_responses(
      function(req) {
        idx <<- idx + 1
        if (idx > length(responses)) return(responses[[length(responses)]])
        return(responses[[idx]])
      },
      {
        state <- AgentState$new()
        res <- node$run(state)
        
        if (res$status != "success") {
          print(res)
        }
        
        expect_equal(res$status, "success")
        
        output <- res$output[[1]]
        # Use str() to debug if it fails again
        if (!"pullRequest" %in% names(output)) {
           print("Names in output:")
           print(names(output))
           print("Full output structure:")
           print(str(output))
        }
        
        expect_true("pullRequest" %in% names(output))
        expect_equal(output$pullRequest$url, "https://github.com/owner/repo/pull/2")
      }
    )
  })
})

test_that("AgentJulesNode fails gracefully if no API key", {
  withr::with_envvar(list(GOOGLE_API_KEY = "", JULES_API_KEY = ""), {
    node <- AgentJulesNode$new(id = "jules_fail", prompt = "Fix", timeout = 1)
    res <- node$run(AgentState$new())
    expect_equal(res$status, "failed")
    expect_match(res$error, "Neither JULES_API_KEY nor GOOGLE_API_KEY")
  })
})

# <!-- APAF Bioinformatics | test-jules_api.R | Approved | 2026-04-01 -->

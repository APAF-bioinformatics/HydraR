# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-system-prompt.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for system_prompt and context injection
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(httr2)

test_that("OpenAIAPIDriver includes system_prompt in request", {
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

    checked <- FALSE
    mock_handler <- function(req) {
      body <- if (is.list(req$body$data)) req$body$data else jsonlite::fromJSON(rawToChar(req$body$data))
      expect_equal(body$messages[[1]]$role, "system")
      expect_equal(body$messages[[1]]$content, "You are a helpful assistant")
      expect_equal(body$messages[[2]]$role, "user")
      expect_equal(body$messages[[2]]$content, "Hello")
      checked <<- TRUE
      return(mock_resp)
    }

    httr2::with_mocked_responses(
      mock_handler,
      {
        drv$call("Hello", system_prompt = "You are a helpful assistant")
      }
    )
    expect_true(checked)
  })
})

test_that("AnthropicAPIDriver includes system_prompt in request", {
  withr::with_envvar(list(ANTHROPIC_API_KEY = "test_key"), {
    drv <- AnthropicAPIDriver$new()

    mock_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        content = list(list(text = "Claude Response"))
      ), auto_unbox = TRUE))
    )

    checked <- FALSE
    mock_handler <- function(req) {
      body <- if (is.list(req$body$data)) req$body$data else jsonlite::fromJSON(rawToChar(req$body$data))
      expect_equal(body$system, "You are a helpful assistant")
      expect_equal(body$messages[[1]]$role, "user")
      expect_equal(body$messages[[1]]$content, "Hello")
      checked <<- TRUE
      return(mock_resp)
    }

    httr2::with_mocked_responses(
      mock_handler,
      {
        drv$call("Hello", system_prompt = "You are a helpful assistant")
      }
    )
    expect_true(checked)
  })
})

test_that("GeminiAPIDriver includes system_prompt in request", {
  withr::with_envvar(list(GOOGLE_API_KEY = "test_key"), {
    drv <- GeminiAPIDriver$new()

    mock_resp <- httr2::response(
      status_code = 200,
      headers = list("Content-Type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(list(
        candidates = list(list(content = list(parts = list(list(text = "Gemini Response")))))
      ), auto_unbox = TRUE))
    )

    checked <- FALSE
    mock_handler <- function(req) {
      body <- if (is.list(req$body$data)) req$body$data else jsonlite::fromJSON(rawToChar(req$body$data), simplifyVector = FALSE)
      expect_equal(body$systemInstruction$parts[[1]]$text, "You are a helpful assistant")
      expect_equal(body$contents[[1]]$parts[[1]]$text, "Hello")
      checked <<- TRUE
      return(mock_resp)
    }

    httr2::with_mocked_responses(
      mock_handler,
      {
        drv$call("Hello", system_prompt = "You are a helpful assistant")
      }
    )
    expect_true(checked)
  })
})

test_that("AgentLLMNode injects agents.md and skills.md from worktree", {
  tmp_dir <- tempfile("hydrar_test_worktree")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  writeLines("agent instructions", file.path(tmp_dir, "agents.md"))
  writeLines("skill instructions", file.path(tmp_dir, "skills.md"))

  # Create a mock driver that captures the system_prompt
  MockDriver <- R6::R6Class("MockDriver",
    inherit = AgentDriver,
    public = list(
      last_system_prompt = NULL,
      call = function(prompt, model = NULL, system_prompt = NULL, ...) {
        self$last_system_prompt <<- system_prompt
        return("Success")
      }
    )
  )

  drv <- MockDriver$new(id = "mock", working_dir = tmp_dir)
  node <- AgentLLMNode$new(id = "test_node", role = "Core Role", driver = drv)
  state <- AgentState$new()

  node$run(state)

  expect_true(grepl("Core Role", drv$last_system_prompt))
  expect_true(grepl("### Agents Context \\(agents.md\\)", drv$last_system_prompt))
  expect_true(grepl("agent instructions", drv$last_system_prompt))
  expect_true(grepl("### Skills Context \\(skills.md\\)", drv$last_system_prompt))
  expect_true(grepl("skill instructions", drv$last_system_prompt))
})

test_that("AgentLLMNode handles multiple agents_files and skills_files", {
  tmp_dir <- tempfile("hydrar_test_multi")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  f1 <- file.path(tmp_dir, "a1.md")
  f2 <- file.path(tmp_dir, "a2.md")
  s1 <- file.path(tmp_dir, "s1.md")

  writeLines("agent 1", f1)
  writeLines("agent 2", f2)
  writeLines("skill 1", s1)

  MockDriver <- R6::R6Class("MockDriver",
    inherit = AgentDriver,
    public = list(
      last_system_prompt = NULL,
      call = function(prompt, model = NULL, system_prompt = NULL, ...) {
        self$last_system_prompt <<- system_prompt
        return("Success")
      }
    )
  )

  drv <- MockDriver$new(id = "mock")
  node <- AgentLLMNode$new(
    id = "test",
    role = "Role",
    driver = drv,
    agents_files = c(f1, f2),
    skills_files = s1
  )

  node$run(AgentState$new())

  expect_true(grepl("agent 1", drv$last_system_prompt))
  expect_true(grepl("agent 2", drv$last_system_prompt))
  expect_true(grepl("skill 1", drv$last_system_prompt))
  expect_true(grepl("### Additional Agent Context \\(a1.md\\)", drv$last_system_prompt))
  expect_true(grepl("### Additional Agent Context \\(a2.md\\)", drv$last_system_prompt))
})

test_that("Mermaid parser handles comma-separated agents_files and skills_files", {
  src <- 'graph TD
    A["Node | type=llm | role=Role | agents_files=a.md,b.md | skills_files=s.md"]
  '
  parsed <- parse_mermaid(src)
  params <- parsed$nodes$params[[1]]

  expect_equal(params$agents_files, c("a.md", "b.md"))
  expect_equal(params$skills_files, "s.md")
})

# <!-- APAF Bioinformatics | test-system-prompt.R | Approved | 2026-04-03 -->

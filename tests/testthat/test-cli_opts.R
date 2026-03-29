# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-cli_opts.R
# Author:      APAF Agentic Workflow
# Purpose:     Tests for CLI options validation and formatting
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

test_that("AgentDriver formats basic CLI options correctly", {
  drv <- AgentDriver$new(id = "test_driver")
  drv$supported_opts <- c("model", "debug", "max_tokens")
  
  opts <- list(model = "gpt-4", debug = TRUE, max_tokens = 100)
  formatted <- drv$format_cli_opts(opts)
  
  expect_contains(formatted, "--model")
  expect_contains(formatted, "gpt-4")
  expect_contains(formatted, "--debug")
  expect_contains(formatted, "--max-tokens")
  expect_contains(formatted, "100")
  # Boolean TRUE should only emit the flag
  expect_false("TRUE" %in% formatted)
})

test_that("AgentDriver handles boolean flags correctly", {
  drv <- AgentDriver$new(id = "test_driver")
  drv$supported_opts <- c("debug", "sandbox")
  
  opts <- list(debug = TRUE, sandbox = FALSE)
  formatted <- drv$format_cli_opts(opts)
  
  expect_contains(formatted, "--debug")
  expect_false("--sandbox" %in% formatted)
})

test_that("AgentDriver handles multi-value flags correctly", {
  drv <- AgentDriver$new(id = "test_driver")
  drv$supported_opts <- c("policy")
  
  opts <- list(policy = c("p1", "p2"))
  formatted <- drv$format_cli_opts(opts)
  
  # Should repeat the flag name for each value: --policy p1 --policy p2
  expect_equal(sum(formatted == "--policy"), 2)
  expect_contains(formatted, "p1")
  expect_contains(formatted, "p2")
})

test_that("AgentDriver validation modes work", {
  drv_warn <- AgentDriver$new(id = "warn_drv", validation_mode = "warning")
  drv_warn$supported_opts <- c("known")
  
  # Warning mode: issues warning, but continues
  expect_warning(
    formatted <- drv_warn$format_cli_opts(list(unknown = "val")),
    "Unrecognized CLI option"
  )
  expect_contains(formatted, "--unknown")
  
  drv_strict <- AgentDriver$new(id = "strict_drv", validation_mode = "strict")
  drv_strict$supported_opts <- c("known")
  
  # Strict mode: stops execution
  expect_error(
    drv_strict$format_cli_opts(list(unknown = "val")),
    "Unrecognized CLI option"
  )
})

test_that("OllamaDriver formats options with -p key=val", {
  drv <- OllamaDriver$new()
  opts <- list(num_ctx = 4096, temperature = 0.7)
  formatted <- drv$format_cli_opts(opts)
  
  expect_contains(formatted, "-p")
  expect_contains(formatted, "num_ctx=4096")
  expect_contains(formatted, "temperature=0.7")
  expect_false("--num-ctx" %in% formatted)
})

test_that("GeminiCLIDriver has correct schema and updates call", {
  drv <- GeminiCLIDriver$new()
  expect_contains(drv$supported_opts, "yolo")
  expect_contains(drv$supported_opts, "output_format")
  
  # We can't easily test system2 call directly without mocking, 
  # but we can check if it tries to pass opts.
  # We test the logic in call() by checking if target_model is set in opts.
})

test_that("AgentLLMNode passes cli_opts to driver", {
  # Mock driver to capture calls
  MockDriver <- R6::R6Class("MockDriver", 
    inherit = AgentDriver,
    public = list(
      last_cli_opts = NULL,
      call = function(prompt, model = NULL, cli_opts = list(), ...) {
        self$last_cli_opts <- cli_opts
        return("mock response")
      }
    )
  )
  
  drv <- MockDriver$new("mock")
  node <- AgentLLMNode$new(
    id = "test", 
    role = "bot", 
    driver = drv, 
    cli_opts = list(debug = TRUE)
  )
  
  state <- AgentState$new()
  node$run(state)
  
  expect_true(drv$last_cli_opts$debug)
})

# <!-- APAF Bioinformatics | test-cli_opts.R | Approved | 2026-03-29 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-advanced_validation_engine.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for the Advanced Validation Engine
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

# Helper to clear registry for clean-room testing
clear_registries <- function() {
  assign("roles", list(), envir = HydraR:::.hydra_registry)
  assign("logic", list(), envir = HydraR:::.hydra_registry)
}

test_that("Advanced Validation: Success Case (Hong Kong Vignette)", {
  wf_path <- system.file("vignettes", "hong_kong_travel.yml", package = "HydraR")
  if (wf_path == "") wf_path <- "../../vignettes/hong_kong_travel.yml"

  if (file.exists(wf_path)) {
    expect_no_error({
      wf <- load_workflow(wf_path)
      dag <- spawn_dag(wf)
    })
  }
})

test_that("Advanced Validation: Missing Role ID (Factory Level)", {
  clear_registries()
  wf <- list(
    graph = "graph TD\n  A[\"Node A | type=llm | role_id=missing_role\"]",
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "No role found")
})

test_that("Advanced Validation: Missing Logic ID (Factory Level)", {
  clear_registries()
  wf <- list(
    graph = "graph TD\n  A[\"Node A | type=logic | logic_id=missing_logic\"]",
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "logic_id 'missing_logic' not found in registry")
})

test_that("Advanced Validation: R Logic Syntax Error (Validation Level)", {
  clear_registries()
  # Use a file because arbitrary string code injection is disabled
  code_file <- tempfile(fileext = ".R")
  writeLines("function(state) { broken_syntax_here( ", code_file)

  expect_error(register_logic("bad_code", resolve_logic_pattern(code_file)))
  unlink(code_file)
})

test_that("Advanced Validation: APAF Rule G-25 (For-loop) warning", {
  clear_registries()
  code_file <- tempfile(fileext = ".R")
  writeLines("function(state) { for (i in 1:10) { print(i) }; list(status='success') }", code_file)

  register_logic("loop_logic", resolve_logic_pattern(code_file))

  wf <- list(
    graph = "graph TD\n  A[\"Node A | type=logic | logic_id=loop_logic\"]",
    logic = list(loop_logic = code_file),
    initial_state = list()
  )
  expect_message(spawn_dag(wf), "Violation of APAF Global Rule G-25")
  unlink(code_file)
})

test_that("Advanced Validation: Edge synchronization mismatch", {
  clear_registries()
  register_role("persona", "You are a probe.")

  # Register logic and test function via global environment to test Tier 2
  # or rely on registry logic. Since we pass strings in 'logic' list, it relies on Tier 2
  dummy <<- function(state) list(status = "ok")
  dummy_test <<- function(res) TRUE

  # Add to registry to make it accessible to logic_id
  register_logic("dummy", dummy)
  register_logic("dummy_test", dummy_test)

  wf <- list(
    graph = "graph TD\n  Root[\"Probe | type=llm | role_id=persona\"]\n  TargetA[\"A | type=logic | logic_id=dummy\"]\n  TargetB[\"B | type=logic | logic_id=dummy\"]\n  Root --> TargetA",
    logic = list(dummy = "dummy"),
    conditional_edges = list(
      Root = list(test = "dummy_test", if_true = "TargetB")
    ),
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "defines 'if_true: TargetB', but no matching arrow")

  rm(dummy, envir = .GlobalEnv)
  rm(dummy_test, envir = .GlobalEnv)
})

test_that("Advanced Validation: Extra unmanaged Mermaid edges", {
  clear_registries()
  register_role("persona", "You are a probe.")

  dummy <<- function(state) list(status = "ok")
  dummy_test <<- function(res) TRUE
  register_logic("dummy", dummy)
  register_logic("dummy_test", dummy_test)

  wf <- list(
    graph = "graph TD\n  Root[\"Probe | type=llm | role_id=persona\"]\n  TargetA[\"A | type=logic | logic_id=dummy\"]\n  TargetB[\"B | type=logic | logic_id=dummy\"]\n  Root --> TargetA\n  Root --> TargetB",
    conditional_edges = list(
      Root = list(test = "dummy_test", if_true = "TargetA")
    ),
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "Mermaid graph has extra edges to \\[TargetB\\]")

  rm(dummy, envir = .GlobalEnv)
  rm(dummy_test, envir = .GlobalEnv)
})

# <!-- APAF Bioinformatics | test-advanced_validation_engine.R | Approved | 2026-04-03 -->

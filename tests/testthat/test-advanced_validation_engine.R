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
  code <- "function(state) { broken_syntax_here( "
  # We use the internal resolver to register it properly
  register_logic("bad_code", resolve_logic_pattern(code))

  wf <- list(
    graph = "graph TD\n  A[\"Node A | type=logic | logic_id=bad_code\"]",
    logic = list(bad_code = code),
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "Syntactic error")
})

test_that("Advanced Validation: APAF Rule G-25 (For-loop) warning", {
  clear_registries()
  code <- "for (i in 1:10) { print(i) }; list(status='success')"
  register_logic("loop_logic", resolve_logic_pattern(code))

  wf <- list(
    graph = "graph TD\n  A[\"Node A | type=logic | logic_id=loop_logic\"]",
    logic = list(loop_logic = code),
    initial_state = list()
  )
  expect_message(spawn_dag(wf), "Violation of APAF Global Rule G-25")
})

test_that("Advanced Validation: Edge synchronization mismatch", {
  clear_registries()
  register_role("persona", "You are a probe.")
  register_logic("dummy", function(state) list(status = "ok"))

  wf <- list(
    graph = "graph TD\n  Root[\"Probe | type=llm | role_id=persona\"]\n  TargetA[\"A | type=logic | logic_id=dummy\"]\n  TargetB[\"B | type=logic | logic_id=dummy\"]\n  Root --> TargetA",
    logic = list(dummy = "{ list(status='ok') }"),
    conditional_edges = list(
      Root = list(test = "TRUE", if_true = "TargetB")
    ),
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "defines 'if_true: TargetB', but no matching arrow")
})

test_that("Advanced Validation: Extra unmanaged Mermaid edges", {
  clear_registries()
  register_role("persona", "You are a probe.")
  register_logic("dummy", function(state) list(status = "ok"))

  wf <- list(
    graph = "graph TD\n  Root[\"Probe | type=llm | role_id=persona\"]\n  TargetA[\"A | type=logic | logic_id=dummy\"]\n  TargetB[\"B | type=logic | logic_id=dummy\"]\n  Root --> TargetA\n  Root --> TargetB",
    conditional_edges = list(
      Root = list(test = "TRUE", if_true = "TargetA")
    ),
    initial_state = list()
  )
  expect_error(spawn_dag(wf), "Mermaid graph has extra edges to \\[TargetB\\]")
})

# <!-- APAF Bioinformatics | test-advanced_validation_engine.R | Approved | 2026-04-03 -->

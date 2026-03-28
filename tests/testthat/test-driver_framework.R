#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        test-driver_framework.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Tests for CLI Drivers and Tool Injection
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

library(testthat)
library(HydraR)

test_that("AgentTool can be created and formatted", {
  my_tool <- AgentTool$new(
    name = "run_blast",
    description = "Runs a BLAST search on a sequence.",
    parameters = list(sequence = "FASTA string", database = "DB name"),
    example = "run_blast(sequence='ATGC', database='nr')"
  )
  
  expect_equal(my_tool$name, "run_blast")
  expect_equal(my_tool$description, "Runs a BLAST search on a sequence.")
  
  fmt <- my_tool$format()
  expect_true(grepl("Tool: run_blast", fmt))
  expect_true(grepl("sequence : FASTA string", fmt))
  expect_true(grepl("database : DB name", fmt))
  expect_true(grepl("run_blast\\(sequence='ATGC', database='nr'\\)", fmt))
})

test_that("AgentLLMNode injects tools into prompt builder", {
  my_tool <- AgentTool$new(
    name = "run_blast",
    description = "Runs a BLAST search on a sequence."
  )
  
  driver <- GeminiCLIDriver$new(id = "test_driver")
  node <- AgentLLMNode$new(
    id = "blast_node",
    role = "You are a bioinformatics assistant.",
    driver = driver,
    tools = list(my_tool)
  )
  
  tool_injection <- format_toolset(node$tools)
  full_prompt <- sprintf("System: %s%s\n\nUser: %s", node$role, tool_injection, "How do I run BLAST?")
  
  expect_true(grepl("AVAILABLE TOOLS", full_prompt))
  expect_true(grepl("run_blast", full_prompt))
  expect_true(grepl("You are a bioinformatics assistant.", full_prompt))
})

test_that("CLI Drivers are correctly instantiated", {
  claude_driver <- ClaudeCodeDriver$new()
  expect_equal(claude_driver$id, "claude_cli")
  expect_true(inherits(claude_driver, "AgentDriver"))
  
  copilot_driver <- CopilotCLIDriver$new()
  expect_equal(copilot_driver$id, "copilot_cli")
  expect_true(inherits(copilot_driver, "AgentDriver"))
})

# <!-- APAF Bioinformatics | test-driver_framework.R | Approved | 2026-03-28 -->

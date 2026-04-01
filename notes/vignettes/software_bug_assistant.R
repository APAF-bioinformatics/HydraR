## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
bug_logic_registry <- list(
  # 0. Initial Configuration
  initial_state = list(
    bug_report = "Function crashes when 'x' is missing."
  ),

  # 1. Deterministic Logic Functions
  logic = list(
    Tester = function(state, params) {
      patch <- state$get("Analyzer")

      # 2. Extract code block
      if (grepl("```r", patch, ignore.case = TRUE)) {
        patch <- strsplit(patch, "```[rR]\n")[[1]][2]
        patch <- strsplit(patch, "\n```")[[1]][1]
      } else if (grepl("```", patch)) {
        patch <- strsplit(patch, "```\n")[[1]][2]
        patch <- strsplit(patch, "\n```")[[1]][1]
      }

      # Mock evaluation logic: In our scenario, the fix must use is.null().
      if (grepl("is.null", patch, fixed = TRUE)) {
        list(status = "SUCCESS", output = list(
          tests_passed = TRUE,
          test_feedback = "All 5 tests passed successfully."
        ))
      } else {
        list(status = "SUCCESS", output = list(
          tests_passed = FALSE,
          test_feedback = "Error: object 'NULL' not found. Did you mean to use 'is.null()'?"
        ))
      }
    }
  ),

  # 2. LLM Agent Roles
  roles = list(
    Analyzer = "You are a software engineer specializing in fixing R bugs. Review the bug report and any previous test failures, then provide a corrected R code snippet."
  ),

  # 3. LLM Prompt Builders
  prompts = list(
    Analyzer = function(state) {
      feedback_text <- if (!is.null(state$get("Tester"))) sprintf("\nTest Feedback: %s", state$get("Tester")) else ""
      sprintf("Bug Report: %s%s\nOutput exactly a snippet of R code.", state$get("bug_report"), feedback_text)
    }
  )
)

## ----factory------------------------------------------------------------------
bug_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (!is.null(params[["driver"]]) && params[["driver"]] == "gemini") GeminiCLIDriver$new() else NULL

  if (id %in% names(bug_logic_registry$logic)) {
    # Create a deterministic Logic Node
    AgentLogicNode$new(
      id = id,
      label = label,
      logic_fn = bug_logic_registry$logic[[id]]
    )
  } else {
    # Create an agentic LLM Node
    AgentLLMNode$new(
      id = id,
      label = label,
      role = bug_logic_registry$roles[[id]],
      driver = driver_obj,
      prompt_builder = bug_logic_registry$prompts[[id]]
    )
  }
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Analyzer[Debugger Agent | driver=gemini] --> Tester
  Tester[Test Suite] -- Test Failed --> Analyzer
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = bug_node_factory)

# Add conditional logic for the self-healing loop
dag$add_conditional_edge(
  from = "Tester",
  test = function(out) isTRUE(out$tests_passed),
  if_true = NULL, # End execution
  if_false = "Analyzer" # Retry
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(compiled_dag$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat("Starting Automatic Bug Remediation...\n")
# 
# result <- compiled_dag$run(
#   initial_state = bug_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# cat("\n--- RESOLUTION RESULT ---\n")
# cat("Final Patch Proposed:", result$state$get("Analyzer"), "\n")
# cat("Test Results:", result$state$get("test_feedback"), "\n")


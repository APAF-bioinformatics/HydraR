test_that("Software Bug Assistant DAG resolves bug through iterative testing", {
  
  dag <- AgentDAG$new()
  
  analyzer_node <- AgentLogicNode$new(id = "Analyzer", logic_fn = function(state, memory = NULL) {
    attempts <- state$get("patch_attempts")
    if (is.null(attempts)) attempts <- 0
    attempts <- attempts + 1
    
    proposed_patch <- if (attempts == 1) {
      "if (x == NULL) return 0;"
    } else {
      "if (is.null(x)) return(0)"
    }
    
    list(
      status = "SUCCESS",
      output = list(
        proposed_patch = proposed_patch,
        patch_attempts = attempts
      )
    )
  })
  dag$add_node(analyzer_node)
  
  tester_node <- AgentLogicNode$new(id = "Tester", logic_fn = function(state, memory = NULL) {
    if (state$get("proposed_patch") == "if (is.null(x)) return(0)") {
      list(status = "SUCCESS", output = list(tests_passed = TRUE))
    } else {
      list(status = "SUCCESS", output = list(tests_passed = FALSE))
    }
  })
  dag$add_node(tester_node)
  
  dag$set_start_node("Analyzer")
  dag$add_edge("Analyzer", "Tester")
  dag$add_conditional_edge(
    from = "Tester",
    test = function(out) isTRUE(out$tests_passed),
    if_true = NULL,
    if_false = "Analyzer"
  )
  
  compiled_dag <- dag$compile()
  
  result <- compiled_dag$run(
    initial_state = list(bug_report = "Crash"),
    max_steps = 10
  )
  
  # Assertions
  expect_equal(result$state$get("patch_attempts"), 2)
  expect_true(result$state$get("tests_passed"))
  expect_equal(result$state$get("proposed_patch"), "if (is.null(x)) return(0)")
})

# <!-- APAF Bioinformatics | test-software_bug_assistant.R | Approved | 2026-03-29 -->

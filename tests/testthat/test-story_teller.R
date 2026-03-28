test_that("Story Teller DAG properly runs the iterative critique loop", {
  # 1. Initialize DAG
  dag <- AgentDAG$new()
  
  # 2. Add Writer Node
  writer_node <- AgentLogicNode$new(id = "Writer", logic_fn = function(state, memory = NULL) {
    current_draft <- state$get("story_draft")
    iteration <- state$get("writer_iterations")
    if (is.null(iteration)) iteration <- 0
    feedback <- state$get("reviewer_feedback")
    
    iteration <- iteration + 1
    
    if (is.null(current_draft)) {
      new_draft <- "Once upon a time, a brave knight went on a quest."
    } else {
      new_draft <- paste(current_draft, "He fought a dragon and saved the kingdom.")
    }
    
    list(
      status = "SUCCESS", 
      output = list(
        story_draft = new_draft, 
        writer_iterations = iteration
      )
    )
  })
  dag$add_node(writer_node)
  
  # 3. Add Reviewer Node
  reviewer_node <- AgentLogicNode$new(id = "Reviewer", logic_fn = function(state, memory = NULL) {
    iteration <- state$get("writer_iterations")
    
    if (iteration >= 2) {
      list(status = "SUCCESS", output = list(is_approved = TRUE, reviewer_feedback = "Approved."))
    } else {
      list(status = "SUCCESS", output = list(is_approved = FALSE, reviewer_feedback = "Needs work."))
    }
  })
  dag$add_node(reviewer_node)
  
  # 4. Define Transitions
  dag$set_start_node("Writer")
  dag$add_edge("Writer", "Reviewer")
  dag$add_conditional_edge(
    from = "Reviewer",
    test = function(out) isTRUE(out$is_approved),
    if_true = NULL,
    if_false = "Writer"
  )
  
  # 5. Compile and Run
  compiled_dag <- dag$compile()
  result <- compiled_dag$run(initial_state = list(), max_steps = 10)
  
  # 6. Assertions
  expect_equal(result$state$get("writer_iterations"), 2)
  expect_true(result$state$get("is_approved"))
  expect_match(result$state$get("story_draft"), "He fought a dragon")
})

# <!-- APAF Bioinformatics | test-story_teller.R | Approved | 2026-03-29 -->

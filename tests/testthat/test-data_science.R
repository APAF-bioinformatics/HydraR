test_that("Data Science DAG loops until accuracy is met", {
  
  dag <- AgentDAG$new()
  
  # Cleaner
  cleaner_node <- AgentLogicNode$new(id = "DataCleaner", logic_fn = function(state, memory = NULL) {
    list(status = "SUCCESS", output = list(clean_data = "Clean Data"))
  })
  dag$add_node(cleaner_node)
  
  # Trainer
  trainer_node <- AgentLogicNode$new(id = "ModelTrainer", logic_fn = function(state, memory = NULL) {
    complexity <- state$get("model_complexity")
    if (is.null(complexity)) complexity <- 1
    new_complexity <- complexity + 1
    
    acc <- 0.60 + (new_complexity * 0.10)
    
    list(
      status = "SUCCESS",
      output = list(
        model_complexity = new_complexity,
        model_accuracy = acc
      )
    )
  })
  dag$add_node(trainer_node)
  
  # Evaluator
  evaluator_node <- AgentLogicNode$new(id = "Evaluator", logic_fn = function(state, memory = NULL) {
    acc <- state$get("model_accuracy")
    target <- state$get("target_accuracy")
    
    if (acc >= target) {
      list(status = "SUCCESS", output = list(optimization_complete = TRUE))
    } else {
      list(status = "SUCCESS", output = list(optimization_complete = FALSE))
    }
  })
  dag$add_node(evaluator_node)
  
  # Transitions
  dag$set_start_node("DataCleaner")
  dag$add_edge("DataCleaner", "ModelTrainer")
  dag$add_edge("ModelTrainer", "Evaluator")
  dag$add_conditional_edge(
    from = "Evaluator",
    test = function(out) isTRUE(out$optimization_complete),
    if_true = NULL,
    if_false = "ModelTrainer"
  )
  
  compiled_dag <- dag$compile()
  
  # Run target = 0.85
  # Attempt 1: complexity = 2 -> acc = 0.80 (Fail)
  # Attempt 2: complexity = 3 -> acc = 0.90 (Pass)
  result <- compiled_dag$run(
    initial_state = list(raw_data = "Raw", target_accuracy = 0.85),
    max_steps = 10
  )
  
  # Assertions
  expect_equal(result$state$get("model_complexity"), 3)
  expect_equal(result$state$get("model_accuracy"), 0.90)
  expect_true(result$state$get("optimization_complete"))
  expect_equal(result$state$get("clean_data"), "Clean Data")
})

# <!-- APAF Bioinformatics | test-data_science.R | Approved | 2026-03-29 -->

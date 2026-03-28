# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-data_science.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Data Science Scenario
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

# Mock Driver for testing LLM nodes
MockDriver <- R6::R6Class("MockDriver",
  inherit = AgentDriver,
  public = list(
    last_prompt = NULL,
    response = "Mocked Response",
    initialize = function(id = "mock", response = "Mocked Response") {
      super$initialize(id)
      self$response <- response
    },
    call = function(prompt, ...) {
      self$last_prompt <- prompt
      return(self$response)
    }
  )
)

test_that("Data Science AutoML loop works", {
  driver <- MockDriver$new(response = "Model Config")
  
  dag <- AgentDAG$new()
  
  # 1. Cleaner
  dag$add_node(AgentLogicNode$new(
    id = "DataCleaner",
    logic_fn = function(state) list(status = "SUCCESS", output = list(clean_data = "CLEANED DATA"))
  ))
  
  # 2. Trainer
  dag$add_node(AgentLLMNode$new(
    id = "ModelTrainer",
    role = "Trainer",
    driver = driver,
    prompt_builder = function(state) paste("Train on:", state$get("clean_data"))
  ))
  
  # 3. Evaluator
  eval_count <- 0
  dag$add_node(AgentLogicNode$new(
    id = "Evaluator",
    logic_fn = function(state) {
      eval_count <<- eval_count + 1
      # Accuracy improves per call
      accuracy <- min(0.60 + (eval_count * 0.10), 0.95)
      
      if (accuracy >= state$get("target_accuracy")) {
        list(status = "SUCCESS", output = list(optimization_complete = TRUE))
      } else {
        list(status = "SUCCESS", output = list(optimization_complete = FALSE))
      }
    }
  ))
  
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
  
  # Run the DAG
  result <- compiled_dag$run(
    initial_state = list(target_accuracy = 0.85),
    max_steps = 10
  )
  
  # Assertions
  # 0.60 -> 0.70 -> 0.80 -> 0.90 (Success)
  expect_equal(eval_count, 3) 
  expect_equal(result$state$get("ModelTrainer"), "Model Config")
})

# <!-- APAF Bioinformatics | test-data_science.R | Approved | 2026-03-29 -->

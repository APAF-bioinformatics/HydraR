## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
ds_logic_registry <- list(
  # 0. Initial Configuration
  initial_state = list(
    raw_data = "Titanic_Dataset.csv",
    target_accuracy = 0.85,
    total_evaluations = 0
  ),

  # 1. Deterministic Logic Functions
  logic = list(
    DataCleaner = function(state, params) {
      dataset <- state$get("raw_data")
      clean_data <- paste("Cleaned", dataset)
      list(status = "SUCCESS", output = list(clean_data = clean_data))
    },
    Evaluator = function(state, params) {
      config <- state$get("ModelTrainer")
      target <- state$get("target_accuracy")
      iteration <- state$get("total_evaluations") + 1

      accuracy <- min(0.60 + (iteration * 0.10), 0.95)

      if (accuracy >= target) {
        list(status = "SUCCESS", output = list(
          optimization_complete = TRUE,
          eval_message = sprintf("Target reached: %.2f >= %.2f using config: %s", accuracy, target, config),
          total_evaluations = iteration
        ))
      } else {
        list(status = "SUCCESS", output = list(
          optimization_complete = FALSE,
          eval_message = sprintf("Accuracy %.2f is below %.2f. Recommending new parameters.", accuracy, target),
          total_evaluations = iteration
        ))
      }
    }
  ),

  # 2. LLM Agent Roles
  roles = list(
    ModelTrainer = "You are an AutoML expert. Given a dataset and previous accuracy logs, recommend a new set of hyperparameters."
  ),

  # 3. LLM Prompt Builders
  prompts = list(
    ModelTrainer = function(state) {
      feedback_text <- if (!is.null(state$get("Evaluator"))) sprintf("\nFeedback: %s", state$get("Evaluator")) else ""
      sprintf("Dataset: %s%s\nOutput exactly a model configuration string.", state$get("clean_data"), feedback_text)
    }
  )
)

## ----factory------------------------------------------------------------------
ds_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (!is.null(params$driver) && params$driver == "gemini") GeminiCLIDriver$new() else NULL

  if (id %in% names(ds_logic_registry$logic)) {
    # Create a deterministic Logic Node
    AgentLogicNode$new(
      id = id,
      label = label,
      logic_fn = ds_logic_registry$logic[[id]]
    )
  } else {
    # Create an agentic LLM Node
    AgentLLMNode$new(
      id = id,
      label = label,
      role = ds_logic_registry$roles[[id]],
      driver = driver_obj,
      prompt_builder = ds_logic_registry$prompts[[id]]
    )
  }
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  DataCleaner[Data Preprocessor] --> ModelTrainer
  ModelTrainer[AutoML Optimizer | driver=gemini] --> Evaluator
  Evaluator[Threshold Guard] -- Needs Improvement --> ModelTrainer
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = ds_node_factory)

# Add conditional logic for the optimization loop
dag$add_conditional_edge(
  from = "Evaluator",
  test = function(out) isTRUE(out$optimization_complete),
  if_true = NULL, # Done!
  if_false = "ModelTrainer"
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(compiled_dag$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat("Starting AutoML Pipeline...\n")
# 
# result <- compiled_dag$run(
#   initial_state = ds_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# cat("\n--- TRAINING PIPELINE COMPLETE ---\n")
# cat("Final Training Config:", result$state$get("ModelTrainer"), "\n")
# cat("Final Accuracy Status:", result$state$get("eval_message"), "\n")


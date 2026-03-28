# Agentic Data Science Assistant

## Introduction

This vignette demonstrates the **Data Science Assistant** pattern using
`HydraR`.

In machine learning workflows, hyperparameter tuning is an inherently
iterative process. We can map this paradigm to an `AgentDAG`. The
workflow contains an initial data setup phase followed by a cyclic model
optimization phase: 1. **Data Cleaner Node**: Ingests and prepares the
raw data. 2. **Model Trainer Node**: Mocks training a model using a set
of hyperparameters. 3. **Evaluator Node**: Assesses the model’s
accuracy. If it falls below the target threshold, it routes back to the
Trainer to adjust parameters.

## Setup

``` r

library(HydraR)
```

## Building the DAG

Initialize the `AgentDAG`.

``` r

dag <- AgentDAG$new()
```

### 1. The Data Cleaner Node

Prepares the data exactly once.

``` r

cleaner_node <- AgentLogicNode$new(id = "DataCleaner", logic_fn = function(state, memory = NULL) {
  dataset <- state$get("raw_data")

  # Mock cleaning
  clean_data <- paste("Cleaned", dataset)

  list(
    status = "SUCCESS",
    output = list(
      clean_data = clean_data
    )
  )
})

dag$add_node(cleaner_node)
```

### 2. The Model Trainer Node

Trains the model iteratively. It increases the “epoch” or “complexity”
every time it gets called by the Evaluator.

``` r

trainer_node <- AgentLogicNode$new(id = "ModelTrainer", logic_fn = function(state, memory = NULL) {
  clean_data <- state$get("clean_data")

  complexity <- state$get("model_complexity")
  if (is.null(complexity)) complexity <- 1

  # Increase complexity on each training loop
  new_complexity <- complexity + 1

  # Mocking training: accuracy improves with complexity, capping at 0.95
  model_accuracy <- min(0.60 + (new_complexity * 0.10), 0.95)

  list(
    status = "SUCCESS",
    output = list(
      model_complexity = new_complexity,
      model_accuracy = model_accuracy,
      model_artifact = sprintf("Model_v%d", new_complexity)
    )
  )
})

dag$add_node(trainer_node)
```

### 3. The Evaluator Node

Compares the accuracy to the user’s requirement.

``` r

evaluator_node <- AgentLogicNode$new(id = "Evaluator", logic_fn = function(state, memory = NULL) {
  accuracy <- state$get("model_accuracy")
  target <- state$get("target_accuracy")

  if (accuracy >= target) {
    list(
      status = "SUCCESS",
      output = list(
        optimization_complete = TRUE,
        eval_message = sprintf("Target reached: %.2f >= %.2f", accuracy, target)
      )
    )
  } else {
    list(
      status = "SUCCESS",
      output = list(
        optimization_complete = FALSE,
        eval_message = sprintf("Accuracy %.2f is below %.2f. Retraining.", accuracy, target)
      )
    )
  }
})

dag$add_node(evaluator_node)
```

## Defining Transitions

Configure the linear start and the cyclic optimization loop.

``` r

dag$set_start_node("DataCleaner")

dag$add_edge("DataCleaner", "ModelTrainer")
dag$add_edge("ModelTrainer", "Evaluator")

dag$add_conditional_edge(
  from = "Evaluator",
  test = function(out) {
    isTRUE(out$optimization_complete)
  },
  if_true = NULL, # Done!
  if_false = "ModelTrainer" # Needs more complexity
)

compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Running the Scenario

Let’s test it with a target accuracy constraint.

``` r

initial_state <- list(
  raw_data = "Titanic_Dataset.csv",
  target_accuracy = 0.85
)

cat("Starting AutoML Pipeline...\n")
#> Starting AutoML Pipeline...
result <- compiled_dag$run(initial_state = initial_state, max_steps = 10)
#> Graph compiled successfully.
#> [Iteration 1] Running Node: DataCleaner
#>    [DataCleaner] Executing R logic...
#> [Iteration 2] Running Node: ModelTrainer
#>    [ModelTrainer] Executing R logic...
#> [Iteration 3] Running Node: Evaluator
#>    [Evaluator] Executing R logic...
#> [Iteration 4] Running Node: ModelTrainer
#>    [ModelTrainer] Executing R logic...
#> [Iteration 5] Running Node: Evaluator
#>    [Evaluator] Executing R logic...

cat("\n--- TRAINING PIPELINE COMPLETE ---\n")
#> 
#> --- TRAINING PIPELINE COMPLETE ---
cat("Clean Data Used:", result$state$get("clean_data"), "\n")
#> Clean Data Used: Cleaned Titanic_Dataset.csv
cat("Final Model Artifact:", result$state$get("model_artifact"), "\n")
#> Final Model Artifact: Model_v3
cat("Final Accuracy:", result$state$get("model_accuracy"), "\n")
#> Final Accuracy: 0.9
cat("Evaluation Message:", result$state$get("eval_message"), "\n")
#> Evaluation Message: Target reached: 0.90 >= 0.85
```

The DAG seamlessly executed the data prep before dropping into an
iterative optimization loop until the target metric was satisfied!

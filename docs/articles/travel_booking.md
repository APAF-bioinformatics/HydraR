# Agentic Travel Booking Concierge

## Introduction

This vignette demonstrates how to orchestrate a **Travel Booking
Concierge** workflow using `HydraR`. A typical travel planning AI must
satisfy various constraints such as the user’s destination, duration,
and crucially, their budget.

In this workflow, we define two nodes: 1. **Travel Planner Node**:
Generates a proposed itinerary and an estimated cost based on user
constraints and previous feedback. 2. **Itinerary Validator Node**:
Receives the proposed itinerary, checks it against the user’s hard
budget constraints, and either approves it or demands a cheaper
alternative.

This demonstrates robust condition handling through cyclic loops.

## Setup

``` r
library(HydraR)
```

## Building the DAG

Initialize the `AgentDAG`.

``` r
dag <- AgentDAG$new()
```

### 1. The Travel Planner Node

This node mocks an LLM calling flight and hotel APIs, receiving feedback
if its previous proposal was too expensive.

``` r
planner_node <- AgentLogicNode$new(id = "Planner", logic_fn = function(state, memory = NULL) {
  # Read user constraints
  destination <- state$get("destination")
  budget <- state$get("budget")

  # Check if we are iterating due to failure
  attempts <- state$get("planner_attempts")
  if (is.null(attempts)) attempts <- 0
  attempts <- attempts + 1

  # Mocking cost reduction on each attempt
  # Attempt 1: $2500, Attempt 2: $1800, Attempt 3: $1200
  base_cost <- 3200
  proposed_cost <- base_cost - (attempts * 700)

  itinerary <- sprintf("Trip to %s. Estimated Cost: $%d.", destination, proposed_cost)

  list(
    status = "SUCCESS",
    output = list(
      proposed_itinerary = itinerary,
      proposed_cost = proposed_cost,
      planner_attempts = attempts
    )
  )
})

dag$add_node(planner_node)
```

### 2. The Itinerary Validator Node

This node ensures the LLM’s proposal strictly adheres to the numerical
budget limit.

``` r
validator_node <- AgentLogicNode$new(id = "Validator", logic_fn = function(state, memory = NULL) {
  proposed_cost <- state$get("proposed_cost")
  budget <- state$get("budget")

  if (proposed_cost <= budget) {
    list(
      status = "SUCCESS",
      output = list(
        is_valid = TRUE,
        validation_message = "Itinerary meets budget requirements. Booking confirmed."
      )
    )
  } else {
    list(
      status = "SUCCESS",
      output = list(
        is_valid = FALSE,
        validation_message = sprintf("Proposed cost ($%d) exceeds budget ($%d). Find cheaper options.", proposed_cost, budget)
      )
    )
  }
})

dag$add_node(validator_node)
```

## Defining Transitions

We define the looping logic. The Validator sends control back to the
Planner if `is_valid` is `FALSE`.

``` r
dag$set_start_node("Planner")

dag$add_edge("Planner", "Validator")

dag$add_conditional_edge(
  from = "Validator",
  test = function(out) {
    isTRUE(out$is_valid)
  },
  if_true = NULL, # Ends execution successfully
  if_false = "Planner" # Loop back for a cheaper proposal
)

compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Running the Scenario

Let’s execute the DAG with a strict budget of `$1500` for a trip to
`Tokyo`.

``` r
initial_state <- list(
  destination = "Tokyo",
  budget = 1500
)

cat("Starting Travel Booking Engine...\n")
#> Starting Travel Booking Engine...
result <- compiled_dag$run(initial_state = initial_state, max_steps = 10)
#> Graph compiled successfully.
#> [Iteration 1] Running Node: Planner
#>    [Planner] Executing R logic...
#> [Iteration 2] Running Node: Validator
#>    [Validator] Executing R logic...
#> [Iteration 3] Running Node: Planner
#>    [Planner] Executing R logic...
#> [Iteration 4] Running Node: Validator
#>    [Validator] Executing R logic...
#> [Iteration 5] Running Node: Planner
#>    [Planner] Executing R logic...
#> [Iteration 6] Running Node: Validator
#>    [Validator] Executing R logic...

# Observe the outcome
cat("\n--- BOOKING RESULT ---\n")
#> 
#> --- BOOKING RESULT ---
cat("Total Planning Attempts:", result$state$get("planner_attempts"), "\n")
#> Total Planning Attempts: 3
cat("Final Itinerary:", result$state$get("proposed_itinerary"), "\n")
#> Final Itinerary: Trip to Tokyo. Estimated Cost: $1100.
cat("Validator Status:", result$state$get("validation_message"), "\n")
#> Validator Status: Itinerary meets budget requirements. Booking confirmed.
```

The DAG successfully cycled back through the Planner node multiple times
until it generated an itinerary that satisfied the budget constraint!

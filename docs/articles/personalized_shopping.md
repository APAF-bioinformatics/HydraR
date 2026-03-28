# Agentic Personalized Shopping Assistant

## Introduction

This vignette demonstrates the **Personalized Shopping Assistant**
pattern using `HydraR`. We define an agentic graph where a
recommendation engine interacts with a mock user.

The two roles are: 1. **Shopper Node**: Acts as the intelligent proxy
that searches the catalogue based on preferences. 2. **User Proxy
Node**: Represents the user. It provides feedback on the recommended
item. If it likes the item, the loop terminates. Otherwise, it gives
feedback and requests a new recommendation.

This models a continuous interaction loop where the agent refines its
search based on real-time feedback.

## Setup

``` r

library(HydraR)
```

## Building the DAG

Initialize the `AgentDAG`.

``` r

dag <- AgentDAG$new()
```

### 1. The Shopper Node

This node uses user feedback to update its recommendations.

``` r

shopper_node <- AgentLogicNode$new(id = "Shopper", logic_fn = function(state, memory = NULL) {
  # Extract state
  request <- state$get("shopping_request")
  feedback <- state$get("user_feedback")

  attempts <- state$get("shopping_attempts")
  if (is.null(attempts)) attempts <- 0
  attempts <- attempts + 1

  # Mocking catalogue search logic
  recommended_item <- if (attempts == 1) {
    "Generic Blue T-Shirt"
  } else if (attempts == 2) {
    "Premium V-Neck T-Shirt"
  } else {
    "Vintage Graphic T-Shirt"
  }

  list(
    status = "SUCCESS",
    output = list(
      recommended_item = recommended_item,
      shopping_attempts = attempts
    )
  )
})

dag$add_node(shopper_node)
```

### 2. The User Proxy Node

This node simulates a picky user.

``` r

user_proxy_node <- AgentLogicNode$new(id = "UserProxy", logic_fn = function(state, memory = NULL) {
  item <- state$get("recommended_item")

  if (item == "Vintage Graphic T-Shirt") {
    list(
      status = "SUCCESS",
      output = list(
        user_is_satisfied = TRUE,
        user_feedback = "I love this graphic tee! I'll buy it."
      )
    )
  } else {
    list(
      status = "SUCCESS",
      output = list(
        user_is_satisfied = FALSE,
        user_feedback = sprintf("I don't like %s. Show me something with a graphic design.", item)
      )
    )
  }
})

dag$add_node(user_proxy_node)
```

## Defining Transitions

Configure the feedback loop.

``` r

dag$set_start_node("Shopper")

dag$add_edge("Shopper", "UserProxy")

dag$add_conditional_edge(
  from = "UserProxy",
  test = function(out) {
    isTRUE(out$user_is_satisfied)
  },
  if_true = NULL, # Done
  if_false = "Shopper" # Try again
)

compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Running the Scenario

Provide the initial request and observe the iterations.

``` r

initial_state <- list(
  shopping_request = "I need a cool t-shirt for the weekend."
)

cat("Starting Personalized Shopper...\n")
#> Starting Personalized Shopper...
result <- compiled_dag$run(initial_state = initial_state, max_steps = 10)
#> Graph compiled successfully.
#> [Iteration 1] Running Node: Shopper
#>    [Shopper] Executing R logic...
#> [Iteration 2] Running Node: UserProxy
#>    [UserProxy] Executing R logic...
#> [Iteration 3] Running Node: Shopper
#>    [Shopper] Executing R logic...
#> [Iteration 4] Running Node: UserProxy
#>    [UserProxy] Executing R logic...
#> [Iteration 5] Running Node: Shopper
#>    [Shopper] Executing R logic...
#> [Iteration 6] Running Node: UserProxy
#>    [UserProxy] Executing R logic...

cat("\n--- SHOPPING RESULT ---\n")
#> 
#> --- SHOPPING RESULT ---
cat("Search Attempts:", result$state$get("shopping_attempts"), "\n")
#> Search Attempts: 3
cat("Final Purchase:", result$state$get("recommended_item"), "\n")
#> Final Purchase: Vintage Graphic T-Shirt
cat("User Feedback:", result$state$get("user_feedback"), "\n")
#> User Feedback: I love this graphic tee! I'll buy it.
```

The DAG refined its recommendation across 3 cycles until the User Proxy
was satisfied!

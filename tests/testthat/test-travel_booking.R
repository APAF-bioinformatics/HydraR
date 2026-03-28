test_that("Travel Booking DAG enforces budget loop", {
  dag <- AgentDAG$new()

  planner_node <- AgentLogicNode$new(id = "Planner", logic_fn = function(state, memory = NULL) {
    destination <- state$get("destination")
    attempts <- state$get("planner_attempts")
    if (is.null(attempts)) attempts <- 0
    attempts <- attempts + 1

    proposed_cost <- 3200 - (attempts * 700)
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

  validator_node <- AgentLogicNode$new(id = "Validator", logic_fn = function(state, memory = NULL) {
    proposed_cost <- state$get("proposed_cost")
    budget <- state$get("budget")

    if (proposed_cost <= budget) {
      list(status = "SUCCESS", output = list(is_valid = TRUE))
    } else {
      list(status = "SUCCESS", output = list(is_valid = FALSE))
    }
  })
  dag$add_node(validator_node)

  dag$set_start_node("Planner")
  dag$add_edge("Planner", "Validator")
  dag$add_conditional_edge(
    from = "Validator",
    test = function(out) isTRUE(out$is_valid),
    if_true = NULL,
    if_false = "Planner"
  )

  compiled_dag <- dag$compile()

  # Run with budget = 1500
  # Attempt 1 -> cost = 2500 (Fail)
  # Attempt 2 -> cost = 1800 (Fail)
  # Attempt 3 -> cost = 1100 (Pass)
  result <- compiled_dag$run(
    initial_state = list(destination = "Tokyo", budget = 1500),
    max_steps = 10
  )

  # Assertions
  expect_equal(result$state$get("planner_attempts"), 3)
  expect_true(result$state$get("is_valid"))
  expect_equal(result$state$get("proposed_cost"), 1100)
})

# <!-- APAF Bioinformatics | test-travel_booking.R | Approved | 2026-03-29 -->

test_that("Personalized Shopping DAG loops until user is satisfied", {
  dag <- AgentDAG$new()

  shopper_node <- AgentLogicNode$new(id = "Shopper", logic_fn = function(state, memory = NULL) {
    attempts <- state$get("shopping_attempts")
    if (is.null(attempts)) attempts <- 0
    attempts <- attempts + 1

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

  user_node <- AgentLogicNode$new(id = "UserProxy", logic_fn = function(state, memory = NULL) {
    if (state$get("recommended_item") == "Vintage Graphic T-Shirt") {
      list(status = "SUCCESS", output = list(user_is_satisfied = TRUE))
    } else {
      list(status = "SUCCESS", output = list(user_is_satisfied = FALSE))
    }
  })
  dag$add_node(user_node)

  dag$set_start_node("Shopper")
  dag$add_edge("Shopper", "UserProxy")
  dag$add_conditional_edge(
    from = "UserProxy",
    test = function(out) isTRUE(out$user_is_satisfied),
    if_true = NULL,
    if_false = "Shopper"
  )

  compiled_dag <- dag$compile()

  result <- compiled_dag$run(
    initial_state = list(shopping_request = "T-shirt"),
    max_steps = 10
  )

  # Assertions
  expect_equal(result$state$get("shopping_attempts"), 3)
  expect_true(result$state$get("user_is_satisfied"))
  expect_equal(result$state$get("recommended_item"), "Vintage Graphic T-Shirt")
})

# <!-- APAF Bioinformatics | test-personalized_shopping.R | Approved | 2026-03-29 -->

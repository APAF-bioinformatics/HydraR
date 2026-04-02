library(testthat)

test_that("AgentMapNode handles element failures gracefully", {
  # Create logic function that fails on specific item
  fail_logic <- function(item, state) {
    if (item == "fail") {
      stop("Simulated error for testing map node element failure")
    }
    return(list(status = "success", output = toupper(item)))
  }

  # Create a mock state
  state <- AgentState$new()
  state$set("test_items", c("pass1", "fail", "pass2"))

  # Create map node
  node <- AgentMapNode$new("map_test", map_key = "test_items", logic_fn = fail_logic)

  # Run node
  result <- node$run(state)

  # Verify result structure
  expect_equal(result$status, "success")
  expect_equal(length(result$output), 3)

  # Verify successful elements
  expect_equal(result$output[[1]]$status, "success")
  expect_equal(result$output[[1]]$output, "PASS1")
  expect_equal(result$output[[3]]$status, "success")
  expect_equal(result$output[[3]]$output, "PASS2")

  # Verify failed element
  expect_equal(result$output[[2]]$status, "failed")
  expect_null(result$output[[2]]$output)
  expect_equal(result$output[[2]]$error, "Simulated error for testing map node element failure")
})

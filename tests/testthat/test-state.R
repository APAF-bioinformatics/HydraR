library(testthat)

test_that("AgentState initializes correctly", {
  state <- AgentState$new(initial_data = list(a = 1, b = "two"))
  expect_equal(state$get("a"), 1)
  expect_equal(state$get("b"), "two")
})

test_that("reducer_append appends elements", {
  state <- AgentState$new(
    initial_data = list(messages = c("msg1")),
    reducers = list(messages = reducer_append)
  )

  state$update(list(messages = "msg2"))
  expect_equal(state$get("messages"), c("msg1", "msg2"))

  state$update(list(messages = "msg3"))
  expect_equal(state$get("messages"), c("msg1", "msg2", "msg3"))
})

test_that("reducer_merge_list merges lists", {
  state <- AgentState$new(
    initial_data = list(config = list(x = 1, y = 2)),
    reducers = list(config = reducer_merge_list)
  )

  state$update(list(config = list(y = 3, z = 4)))

  merged <- state$get("config")
  expect_equal(merged$x, 1)
  expect_equal(merged$y, 3)
  expect_equal(merged$z, 4)
})

test_that("AgentState schema validation works", {
  state <- AgentState$new(
    initial_data = list(count = 0),
    schema = list(count = "double")
  )

  expect_error(state$set("count", "string"), "Schema validation failed")

  # Valid update
  state$set("count", 5)
  expect_equal(state$get("count"), 5)
})

# <!-- APAF Bioinformatics | test-state.R | Approved | 2026-03-29 -->

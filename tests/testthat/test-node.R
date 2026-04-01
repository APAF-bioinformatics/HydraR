library(testthat)

test_that("AgentNode initialization works with defaults", {
  node <- AgentNode$new("test_node")
  expect_equal(node$id, "test_node")
  expect_equal(node$label, "test_node")
  expect_equal(node$params, list())
})

test_that("AgentNode initialization works with custom values", {
  node <- AgentNode$new("test_node", label = "Custom Label", params = list(foo = "bar"))
  expect_equal(node$id, "test_node")
  expect_equal(node$label, "Custom Label")
  expect_equal(node$params$foo, "bar")
})

test_that("AgentNode validation for id works", {
  # stopifnot(is.character(id) && length(id) == 1)
  expect_error(AgentNode$new(123))
  expect_error(AgentNode$new(c("a", "b")))
})

test_that("AgentNode run method throws abstract error", {
  node <- AgentNode$new("test_node")
  expect_error(node$run(NULL), "Method 'run' must be implemented by subclass.")
})

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-messaging.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for HydraR Messaging and Logs
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

test_that("JSONLMessageLog persists and retrieves messages correctly", {
  log_path <- tempfile(fileext = ".jsonl")
  on.exit(if (file.exists(log_path)) unlink(log_path))

  logger <- JSONLMessageLog$new(path = log_path)

  # Log multiple messages
  msg1 <- list(from = "nodeA", to = "nodeB", timestamp = Sys.time(), content = list(val = "test1"))
  msg2 <- list(from = "nodeC", to = "nodeB", timestamp = Sys.time(), content = list(val = "test2"))

  logger$log(msg1)
  logger$log(msg2)

  # Read back
  msgs <- logger$get_all()

  expect_equal(length(msgs), 2)
  expect_equal(msgs[[1]]$from, "nodeA")
  expect_equal(msgs[[2]]$content$val, "test2")
})

test_that("MemoryMessageLog works as a volatile fallback", {
  logger <- MemoryMessageLog$new()
  logger$log(list(from = "A", to = "B", content = list(x = 1)))

  msgs <- logger$get_all()
  expect_equal(length(msgs), 1)
  expect_equal(msgs[[1]]$from, "A")
})

test_that("DuckDBMessageLog schema initialization works", {
  # Mock DuckDB test
  skip_if_not_installed("duckdb")
  db_path <- tempfile(fileext = ".duckdb")
  on.exit(if (file.exists(db_path)) unlink(db_path))

  logger <- DuckDBMessageLog$new(db_path = db_path)
  msg <- list(from = "A", to = "B", timestamp = Sys.time(), content = list(data = 1))

  # This should create the table and write the row
  logger$log(msg)

  msgs <- logger$get_all()
  expect_equal(length(msgs), 1)
  expect_equal(msgs[[1]]$from, "A")
})

# <!-- APAF Bioinformatics | test-messaging.R | Approved | 2026-03-30 -->

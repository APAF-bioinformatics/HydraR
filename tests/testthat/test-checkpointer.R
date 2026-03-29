library(testthat)

test_that("MemorySaver checkpointer works", {
  saver <- MemorySaver$new()
  state <- AgentState$new(list(key = "value"))

  thread_id <- "thread1"
  saver$put(thread_id, state)

  restored <- saver$get(thread_id)
  expect_equal(restored$get("key"), "value")

  # Check non-existent thread
  expect_null(saver$get("nonexistent"))
})

test_that("RDSSaver checkpointer works and creates files", {
  tmp_dir <- tempfile(pattern = "rds_ckpt_")
  saver <- RDSSaver$new(dir = tmp_dir)

  # Directory should be created

  expect_true(dir.exists(tmp_dir))

  state <- AgentState$new(list(alpha = "hello", beta = 42))
  thread_id <- "rds_thread_1"

  # Initial put
  saver$put(thread_id, state)

  # .rds file should exist on disk
  rds_file <- file.path(tmp_dir, paste0(thread_id, ".rds"))
  expect_true(file.exists(rds_file))
  expect_gt(file.size(rds_file), 0)

  # Get back
  restored <- saver$get(thread_id)
  expect_s3_class(restored, "AgentState")
  expect_equal(restored$get("alpha"), "hello")
  expect_equal(restored$get("beta"), 42)

  # Update and put again
  state$set("alpha", "updated")
  saver$put(thread_id, state)

  restored2 <- saver$get(thread_id)
  expect_equal(restored2$get("alpha"), "updated")

  # Non-existent thread returns NULL
  expect_null(saver$get("no_such_thread"))

  # Multiple threads create separate files
  state2 <- AgentState$new(list(gamma = TRUE))
  saver$put("rds_thread_2", state2)
  expect_true(file.exists(file.path(tmp_dir, "rds_thread_2.rds")))
  expect_equal(length(list.files(tmp_dir, pattern = "\\.rds$")), 2)

  # Clean up
  unlink(tmp_dir, recursive = TRUE)
})

test_that("DuckDBSaver checkpointer works and creates db file", {
  skip_if_not_installed("duckdb")

  tmp_db <- tempfile(fileext = ".db")
  saver <- DuckDBSaver$new(db_path = tmp_db)

  # DB file should exist on disk
  expect_true(file.exists(tmp_db))

  state <- AgentState$new(list(x = 10, y = 20))
  thread_id <- "thread2"

  # Initial put
  saver$put(thread_id, state)

  # Get back
  restored <- saver$get(thread_id)
  expect_equal(restored$get("x"), 10)
  expect_equal(restored$get("y"), 20)

  # Update and put again
  state$set("x", 100)
  saver$put(thread_id, state)

  restored2 <- saver$get(thread_id)
  expect_equal(restored2$get("x"), 100)

  # Non-existent thread returns NULL
  expect_null(saver$get("nonexistent"))

  # Clean up
  DBI::dbDisconnect(saver$con, shutdown = TRUE)
})

# <!-- APAF Bioinformatics | test-checkpointer.R | Approved | 2026-03-31 -->

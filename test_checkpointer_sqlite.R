library(testthat)
source("R/state.R")
source("R/checkpointer.R")

test_that("SQLite checkpointer test (mocking DuckDBSaver)", {
  tmp_db <- tempfile(fileext = ".db")
  con <- DBI::dbConnect(RSQLite::SQLite(), tmp_db)

  saver <- DuckDBSaver$new(con = con)

  state <- AgentState$new(list(x = 10, y = 20), reducers = list(z = function(c, n) c(c, n)))
  state$set("z", 1)
  state$update(list(z = 2))

  thread_id <- "thread2"

  # Initial put
  saver$put(thread_id, state)

  # Get back
  restored <- saver$get(thread_id)
  expect_equal(restored$get("x"), 10)
  expect_equal(restored$get("y"), 20)
  expect_equal(restored$get("z"), c(1, 2))

  # verify reducers are still intact
  restored$update(list(z = 3))
  expect_equal(restored$get("z"), c(1, 2, 3))

  # Update and put again
  restored$set("x", 100)
  saver$put(thread_id, restored)

  restored2 <- saver$get(thread_id)
  expect_equal(restored2$get("x"), 100)
  expect_equal(restored2$get("z"), c(1, 2, 3))

  # Non-existent thread returns NULL
  expect_null(saver$get("nonexistent"))

  DBI::dbDisconnect(con)
})

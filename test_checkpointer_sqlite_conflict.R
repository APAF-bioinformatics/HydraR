library(testthat)
source("R/state.R")
source("R/checkpointer.R")

test_that("SQLite conflict test", {
  tmp_db <- tempfile(fileext = ".db")
  con <- DBI::dbConnect(RSQLite::SQLite(), tmp_db)

  saver <- DuckDBSaver$new(con = con)

  state <- AgentState$new(list(x = 10))

  thread_id <- "thread2"

  # Initial put
  saver$put(thread_id, state)

  # Put again should update
  state$set("x", 100)
  saver$put(thread_id, state)

  restored <- saver$get(thread_id)
  expect_equal(restored$get("x"), 100)

  DBI::dbDisconnect(con)
})

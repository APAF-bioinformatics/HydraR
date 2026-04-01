library(testthat)
source("R/utils.R")
source("R/state.R")
source("R/checkpointer.R")
source("R/registry.R")

test_that("DuckDBSaver uses BLOB storage and Registry re-hydration (mocked with RSQLite)", {
  # 1. Setup SQLite
  db_path <- tempfile(fileext = ".db")
  con_main <- DBI::dbConnect(RSQLite::SQLite(), db_path)

  saver <- DuckDBSaver$new(con = con_main)

  # 2. Register a test reducer
  test_val <- 100
  register_logic("test_reducer", function(current, new) {
    (current %||% 0) + new + test_val
  })

  # 3. Create state with the registered reducer
  state <- AgentState$new(initial_data = list(score = 10), reducers = list(score = "test_reducer"))

  # 4. Save
  thread_id <- "blob-test-thread"
  saver$put(thread_id, state)

  # 5. Verify BLOB storage in DB
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # Check columns
  cols <- DBI::dbGetQuery(con, sprintf("PRAGMA table_info('%s')", saver$table_name))
  expect_true("state_data" %in% cols$name)

  df <- DBI::dbGetQuery(con, sprintf("SELECT state_data FROM %s WHERE thread_id = ?", saver$table_name), params = list(thread_id))
  blob <- df$state_data[[1]]
  expect_true(is.raw(blob))
  unserialized_state <- base::unserialize(blob)
  expect_equal(unserialized_state$data$score, 10)
  expect_true(is.function(unserialized_state$reducers$score))

  # 6. Restore and Verify Logic hydration
  restored <- saver$get(thread_id)
  expect_true(inherits(restored, "AgentState"))

  # Trigger the restored reducer
  restored$update(list(score = 5))
  # 10 (initial) + 5 (new) + 100 (test_val) = 115
  expect_equal(restored$get("score"), 115)

  DBI::dbDisconnect(con_main)
})

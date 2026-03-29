library(testthat)
library(HydraR)
library(DBI)

context("Technical Recommendations Verification")

test_that("DuckDBSaver uses JSON storage and Registry re-hydration", {
  skip_if_not_installed("duckdb")
  # 1. Setup DuckDB
  db_path <- tempfile(fileext = ".duckdb")
  on.exit(unlink(db_path), add = TRUE)

  saver <- DuckDBSaver$new(db_path = db_path)

  # 2. Register a test reducer
  test_val <- 100
  register_logic("test_reducer", function(current, new) {
    (current %||% 0) + new + test_val
  })

  # 3. Create state with the registered reducer
  state <- AgentState$new(initial_data = list(score = 10), reducers = list(score = "test_reducer"))

  # 4. Save
  thread_id <- "json-test-thread"
  saver$put(thread_id, state)

  # 5. Verify JSON storage in DB (Human Readability)
  con <- DBI::dbConnect(duckdb::duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # Check columns
  cols <- DBI::dbGetQuery(con, sprintf("PRAGMA table_info('%s')", saver$table_name))
  expect_true("state_json" %in% cols$name)

  df <- DBI::dbGetQuery(con, sprintf("SELECT state_json FROM %s WHERE thread_id = ?", saver$table_name), params = list(thread_id))
  json_str <- df$state_json[[1]]
  expect_match(json_str, "\"score\": 10")
  expect_match(json_str, "\"test_reducer\"")

  # 6. Restore and Verify Logic hydration
  restored <- saver$get(thread_id)
  expect_true(inherits(restored, "AgentState"))

  # Trigger the restored reducer
  restored$update(list(score = 5))
  # 10 (initial) + 5 (new) + 100 (test_val) = 115
  expect_equal(restored$get("score"), 115)
})

test_that("AgentDAG runs iteratively and handles pauses", {
  dag <- AgentDAG$new()

  # Node A: Just increments a counter
  node_a <- AgentLogicNode$new("A", function(state) {
    count <- (state$get("count") %||% 0) + 1
    state$set("count", count)
    list(output = list(count = count), status = "success")
  })

  # Node B: Pauses on first visit
  node_b <- AgentLogicNode$new("B", function(state) {
    visited <- state$get("visited_b") %||% FALSE
    if (!visited) {
      state$set("visited_b", TRUE)
      return(list(output = NULL, status = "pause"))
    }
    list(output = "finished", status = "success")
  })

  dag$add_node(node_a)$add_node(node_b)
  dag$add_edge("A", "B")

  # Run 1: Should pause at B
  res1 <- dag$run(initial_state = list(count = 0), max_steps = 10)
  expect_equal(res1$status, "paused")
  expect_equal(res1$paused_at, "B")
  expect_equal(dag$state$get("count"), 1)

  # Run 2: Resume from B
  # Providing the actual AgentState object for resume
  res2 <- dag$run(initial_state = dag$state, resume_from = "B", max_steps = 10)
  expect_equal(res2$status, "completed")
  expect_equal(dag$state$get("visited_b"), TRUE)
})

test_that("Graph compiler finds conditional edges", {
  dag <- AgentDAG$new()
  node_a <- AgentLogicNode$new("A", function(s) list(output = TRUE))
  node_b <- AgentLogicNode$new("B", function(s) list(output = "B"))
  node_c <- AgentLogicNode$new("C", function(s) list(output = "C"))

  dag$add_node(node_a)$add_node(node_b)$add_node(node_c)

  # A -> B (if TRUE), A -> C (if FALSE)
  dag$add_conditional_edge("A", function(out) out, if_true = "B", if_false = "C")

  dag$compile()

  # Check if igraph has these edges
  expect_true(igraph::are_adjacent(dag$graph, "A", "B"))
  expect_true(igraph::are_adjacent(dag$graph, "A", "C"))
})

# <!-- APAF Bioinformatics | test-recommendations.R | Approved | 2026-03-29 -->

library(testthat)
library(HydraR)

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-phase2.R
# Author:      APAF Agentic Workflow
# Purpose:     Tests for DriverRegistry, RestrictedState, and Messaging
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

test_that("DriverRegistry manages drivers correctly", {
  registry <- DriverRegistry$new()
  drv1 <- AgentDriver$new(id = "test_drv_1", provider = "google", model_name = "gemini-1.5")

  registry$register(drv1)
  expect_equal(registry$get("test_drv_1"), drv1)

  # Metadata listing
  list_df <- registry$list_drivers()
  expect_equal(nrow(list_df), 1)
  expect_equal(list_df$provider[1], "google")

  # Type safety
  expect_error(registry$register(list(id = "fake")), "Only objects inheriting from AgentDriver")
})

test_that("AgentLLMNode supports hot-swapping drivers", {
  registry <- get_driver_registry()
  registry$clear()

  drv1 <- AgentDriver$new(id = "drv1", provider = "p1", model_name = "m1")
  drv2 <- AgentDriver$new(id = "drv2", provider = "p2", model_name = "m2")
  registry$register(drv1)
  registry$register(drv2)

  node <- AgentLLMNode$new(id = "node1", role = "bot", driver = drv1)
  expect_equal(node$driver$id, "drv1")

  # Swap via ID
  node$swap_driver("drv2")
  expect_equal(node$driver$id, "drv2")

  # Swap via Object
  node$swap_driver(drv1)
  expect_equal(node$driver$id, "drv1")
})

test_that("RestrictedState enforces blinding and privacy", {
  global_state <- AgentState$new(initial_data = list(public_key = "hello"))
  node_a_state <- RestrictedState$new(global_state, "node_a")
  node_b_state <- RestrictedState$new(global_state, "node_b")

  # Public access works
  expect_equal(node_a_state$get("public_key"), "hello")

  # Messaging between A and B
  node_a_state$send_message(to = "node_b", content = "Secret Message")

  # Node B can see it
  msgs_b <- node_b_state$receive_messages()
  expect_equal(length(msgs_b), 1)
  expect_equal(msgs_b[[1]]$content, "Secret Message")
  expect_equal(msgs_b[[1]]$from, "node_a")

  # Node A CANNOT see Node B's inbox
  inbox_b_key <- ".__inbox__node_b__"
  expect_error(node_a_state$get(inbox_b_key), "Access Denied")

  # get_all() filters out other inboxes
  all_a <- node_a_state$get_all()
  expect_contains(names(all_a), "public_key")
  expect_false(inbox_b_key %in% names(all_a))
})

test_that("MessageLog captures communication", {
  logger <- MemoryMessageLog$new()
  global_state <- AgentState$new()
  node_a_state <- RestrictedState$new(global_state, "node_a", logger = logger)

  node_a_state$send_message("node_b", "hi")

  logs <- logger$get_all()
  expect_equal(length(logs), 1)
  expect_equal(logs[[1]]$content, "hi")
})

test_that("AgentDAG uses RestrictedState during execution", {
  dag <- AgentDAG$new()
  dag$message_log <- MemoryMessageLog$new()

  # Node A sends a message
  node_a <- AgentLogicNode$new("node_a", logic_fn = function(state) {
    state$send_message("node_b", "Hello from A")
    return(list(output = "ok"))
  })

  # Node B reads the message
  node_b <- AgentLogicNode$new("node_b", logic_fn = function(state) {
    msgs <- state$receive_messages()
    return(list(output = msgs[[1]]$content))
  })

  dag$add_node(node_a)
  dag$add_node(node_b)
  dag$add_edge("node_a", "node_b")

  res <- dag$run(initial_state = list())

  expect_equal(res$results$node_b$output, "Hello from A")

  # Check audit log
  expect_equal(length(dag$message_log$get_all()), 1)
})

# <!-- APAF Bioinformatics | test-phase2.R | Approved | 2026-03-29 -->

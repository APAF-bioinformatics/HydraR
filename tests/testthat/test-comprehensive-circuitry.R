library(testthat)
library(HydraR)

test_that("Scenario 1: Integrated Circuitry (Router -> Map)", {
  # Logic for Router: chooses 'MapNode' if 'go_map' is TRUE
  register_logic("my_router", function(state) {
    if (state$get("go_map") == TRUE) {
      list(target_node = "MapNode", output = "Routing to Map")
    } else {
      list(target_node = "End", output = "Ending early")
    }
  })

  # Logic for Map Item
  register_logic("process_item", function(item, state) {
    list(status = "success", output = paste("Processed", item))
  })

  mermaid_src <- '
  graph TD
    Start["Router | type=router | logic_id=my_router"]
    MapNode["Mapper | type=map | map_key=items | logic_id=process_item"]
    End["Finished"]
    Start --> MapNode
    Start --> End
    MapNode --> End
  '

  dag <- mermaid_to_dag(mermaid_src)
  dag$set_start_node("Start")

  # Run 1: Go to Map
  res1 <- dag$run(initial_state = list(go_map = TRUE, items = list(1, 2, 3)))
  expect_false(is.null(res1$results$MapNode$status))
  expect_equal(length(res1$results$MapNode$output), 3)

  # Run 2: Skip Map
  res2 <- dag$run(initial_state = list(go_map = FALSE))
  expect_true(is.null(res2$results$MapNode$status))
  expect_false(is.null(res2$results$End$status))
})

test_that("Scenario 2: Fault-Tolerant Circular Routing (Loop + ErrorEdge)", {
  # Logic: Node B fails twice, then redirected via error edge
  # Use a global counter to mock internal state across R6 instances if needed,
  # but here we use the AgentState (which is persistent in the DAG run).

  register_logic("A", function(state) list(status = "success"))

  register_logic("B", function(state) {
    # If we failed before, increment a counter in state
    fails <- state$get("fail_count") %||% 0
    if (fails < 1) {
      .GlobalEnv$fail_count <- .GlobalEnv$fail_count + 1
      return(list(status = "failed", output = "Mock Failure"))
    }
    return(list(status = "success", output = "Mock Success"))
  })

  .GlobalEnv$fail_count <- 0

  mermaid_src <- '
  graph TD
    A["LogicA"]
    B["LogicB"]
    C["Recovery"]
    A --> B
    B -- "Test" --> A
    B -- "error" --> C
  '

  dag <- mermaid_to_dag(mermaid_src)
  # A and B are roots, so no need to set start node specifically to run both
  # or set A to start the loop
  dag$set_start_node("A")

  # Run: It should loop A -> B (Fail) -> A -> B (Fail) -- error --> C
  # Wait! B -- error --> C only triggers if B has status "failed" and AN ERROR EDGE exists.
  # add_edge recognizes "error" label.

  res <- dag$run(initial_state = list())

  expect_true("C" %in% names(res$results))
  expect_equal(.GlobalEnv$fail_count, 1) # First failure takes error edge immediately if it exists
  # Wait! Error edge takes priority over Test/Fail labels in .run_iterative!
})

test_that("Scenario 3: Map Node Edge Cases", {
  register_logic("map_logic", function(item, state) list(output = item))

  # A: Missing Key
  node_skip <- AgentMapNode$new("M", map_key = "non_existent", logic_fn = get_logic("map_logic"))
  dag1 <- AgentDAG$new()$add_node(node_skip)$set_start_node("M")
  res1 <- dag1$run(initial_state = list())
  expect_equal(res1$results$M$status, "skip")

  # B: Empty List
  node_empty <- AgentMapNode$new("M", map_key = "empty", logic_fn = get_logic("map_logic"))
  dag2 <- AgentDAG$new()$add_node(node_empty)$set_start_node("M")
  res2 <- dag2$run(initial_state = list(empty = list()))
  expect_equal(res2$results$M$status, "success")
  expect_equal(length(res2$results$M$output), 0)

  # C: Partial Failure
  register_logic("fail_on_2", function(item, state) {
    if (item == 2) stop("Item 2 failed")
    list(status = "success", output = item)
  })
  node_partial <- AgentMapNode$new("M", map_key = "items", logic_fn = get_logic("fail_on_2"))
  dag3 <- AgentDAG$new()$add_node(node_partial)$set_start_node("M")
  res3 <- dag3$run(initial_state = list(items = list(1, 2, 3)))
  expect_equal(res3$results$M$output[[2]]$status, "failed")
  expect_equal(res3$results$M$output[[1]]$output, 1)
})

test_that("Scenario 4: Observer Isolation (Read-Only Enforcement)", {
  .GlobalEnv$obs_hit <- FALSE
  register_logic("my_obs", function(state) {
    .GlobalEnv$obs_hit <- TRUE
    # Attempt to mutate state — this should be blocked by read-only RestrictedState
    state$set("secret", "pwned")
  })

  mermaid_src <- '
  graph TD
    Start["Logic | type=logic | logic_id=my_start"]
    Obs["Observer | type=observer | logic_id=my_obs"]
    Start --> Obs
  '
  register_logic("my_start", function(state) list(status = "success", output = "hello"))

  dag <- mermaid_to_dag(mermaid_src)
  dag$set_start_node("Start")

  # Run should produce a warning from the observer's tryCatch when set() is blocked
  expect_warning(
    res <- dag$run(initial_state = list(secret = "original")),
    "Observer failed.*Read-Only"
  )

  # Observer function was still called (side-effects before the set() worked)
  expect_true(.GlobalEnv$obs_hit)
  # State is PROTECTED — the illegal set() was blocked
  expect_equal(res$state$get("secret"), "original")
})

test_that("Scenario 5: Parallel/Worktree Mock Integration", {
  # Mock LLM Node using LogicNode
  register_logic("parallel_task", function(state) {
    list(status = "success", output = "done")
  })

  mermaid_src <- '
  graph TD
    A["TaskA | isolation=true"]
    B["TaskB | isolation=true"]
    A --> Merge
    B --> Merge
  '
  # We test the iterative mode (multi-branch) without requiring real worktrees
  dag <- mermaid_to_dag(mermaid_src)
  # Roots A and B are auto-detected by run()
  # No single string set_start_node allowed here for multi-roots
  dag$nodes$A$logic_fn <- get_logic("parallel_task")
  dag$nodes$B$logic_fn <- get_logic("parallel_task")
  dag$nodes$Merge$logic_fn <- function(s) list(status="success")

  res <- dag$run(initial_state = list())
  expect_true("Merge" %in% names(res$results))
})

test_that("AgentRouterNode works as expected", {
  # Register logic for router
  register_logic("my_router", function(state) {
    val <- state$get("choice")
    if (val == "A") {
      return(list(target_node = "NodeA", output = "Chose A"))
    } else {
      return(list(target_node = "NodeB", output = "Chose B"))
    }
  })

  mermaid_src <- '
  graph TD
    Start["Router | type=router | logic_id=my_router"]
    NodeA["Logic A"]
    NodeB["Logic B"]
    Start --> NodeA
    Start --> NodeB
  '

  register_logic("NodeA", function(state) list(status = "success", output = "A_hit"))
  register_logic("NodeB", function(state) list(status = "success", output = "B_hit"))

  # Setup DAG
  wf <- list(
    graph = mermaid_src,
    start_node = "Start",
    initial_state = list(choice = "A")
  )

  dag <- spawn_dag(wf)
  res <- dag$run(initial_state = list(choice = "A"))

  expect_equal(res$results$Start$target_node, "NodeA")
  expect_true("NodeA" %in% names(res$results))
  expect_equal(res$results$NodeA$output, "A_hit")
  expect_true(is.null(res$results$NodeB$status))

  # Try choice B
  dag_b <- spawn_dag(wf)
  res_b <- dag_b$run(initial_state = list(choice = "B"))
  expect_equal(res_b$results$Start$target_node, "NodeB")
  expect_equal(res_b$results$NodeB$output, "B_hit")
  expect_true(is.null(res_b$results$NodeA$status))
})

test_that("ErrorEdges work as expected", {
  mermaid_src <- '
  graph TD
    Main["Main | type=logic | logic_id=Failer"]
    Recover["Recover | type=logic | logic_id=Recovery"]
    Main --> Success["Win"]
  '

  register_role("Recovery", "I am a recovery agent.")
  register_logic("Failer", function(state) list(status = "failed", output = "crashed"))
  register_logic("Recovery", function(state) list(status = "success", output = "fixed"))

  wf <- list(
    graph = mermaid_src,
    start_node = "Main",
    error_edges = list("Main" = "Recover")
  )

  dag <- spawn_dag(wf)
  res <- dag$run(initial_state = list())

  expect_equal(res$results$Main$status, "failed")
  expect_true("Recover" %in% names(res$results))
  expect_equal(res$results$Recover$output, "fixed")
  expect_null(res$results$Success$status)
})

test_that("AgentMapNode works as expected", {
  register_logic("my_mapper", function(item, state) {
    return(list(status = "success", output = item * 2))
  })

  mermaid_src <- '
  graph TD
    M["Mapper | type=map | map_key=numbers | logic_id=my_mapper"]
  '

  wf <- list(
    graph = mermaid_src,
    initial_state = list(numbers = c(1, 2, 3))
  )

  dag <- spawn_dag(wf)
  res <- dag$run(initial_state = list(numbers = c(1, 2, 3)))

  expect_equal(length(res$results$M$output), 3)
  expect_equal(res$results$M$output[[1]]$output, 2)
  expect_equal(res$results$M$output[[3]]$output, 6)
})

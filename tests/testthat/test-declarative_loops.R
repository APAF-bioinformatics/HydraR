test_that("Declarative conditional edges work via spawn_dag", {
  # Create a dummy workflow with a loop
  wf_yml <- "
graph: |
  graph TD
    A[Start | type=logic | logic_id=logic_a]
    B[End | type=logic | logic_id=logic_b]
    A --> B
    B -- fail --> A

start_node: A

conditional_edges:
  B:
    test: 'isTRUE(out$ok)'
    if_true: null
    if_false: 'A'

logic:
  logic_a: |
    list(status = 'success', output = 'a_done')
  logic_b: |
    # Loop once, then pass
    count <- state$get('count') %||% 0
    state$set('count', count + 1)
    if (count < 1) {
      list(status = 'success', output = list(ok = FALSE))
    } else {
      list(status = 'success', output = list(ok = TRUE))
    }
"
  # Mock a file since load_workflow needs a path
  tmp_file <- tempfile(fileext = ".yml")
  writeLines(wf_yml, tmp_file)

  # Use load_workflow which SHOULD register the logic
  wf <- load_workflow(tmp_file)

  # Verify registration
  expect_true("logic_a" %in% list_logic())

  dag <- spawn_dag(wf)

  res <- dag$run(initial_state = list(), max_steps = 10)

  expect_equal(res$status, "completed")
  expect_true(dag$state$get("count") >= 2)
})

test_that("Declarative conditional edges handle named functions", {
  # Manually register for this test
  register_logic("my_test_fn", function(out) isTRUE(out$output$pass))
  register_logic("la", function(s) list())
  register_logic("lb", function(s) list(output = list(pass = TRUE)))

  wf <- list(
    graph = "graph TD\nA[A|type=logic|logic_id=la] --> B[B|type=logic|logic_id=lb]\nB --> A",
    start_node = "A",
    conditional_edges = list(
      B = list(test = "my_test_fn", if_true = NULL, if_false = "A")
    )
  )

  dag <- spawn_dag(wf)
  res <- dag$run(initial_state = list())
  expect_equal(res$status, "completed")
})

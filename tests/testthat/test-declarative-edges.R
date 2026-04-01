test_that("Declarative error edges in Mermaid work", {
  mermaid_src <- '
  graph TD
    Main["Failer"]
    Main -- "error" --> Recover["Recovery"]
    Main --> Success["Win"]
  '

  register_logic("Failer", function(state) list(status = "failed", output = "crashed"))
  register_logic("Recovery", function(state) list(status = "success", output = "fixed"))

  dag <- mermaid_to_dag(mermaid_src)
  dag$set_start_node("Main")
  # Manually provide logic because we are not using load_workflow here
  dag$nodes$Main$logic_fn <- get_logic("Failer")
  dag$nodes$Recover$logic_fn <- get_logic("Recovery")

  res <- dag$run(initial_state = list())

  expect_equal(res$results$Main$status, "failed")
  expect_equal(res$results$Recover$output, "fixed")
  expect_null(res$results$Success$status)
})

test_that("Declarative Test/Fail labels in Mermaid work", {
  mermaid_src <- '
  graph TD
    Check["Verify | type=logic | logic_id=v_check"]
    Check -- "Test" --> NodeA["NodeA"]
    Check -- "Fail" --> NodeB["NodeB"]
  '

  register_logic("v_check", function(state) {
    if (state$get("choice") == "good") {
      return(list(status = "success", output = "ok"))
    } else {
      return(list(status = "failed", output = "bad"))
    }
  })

  dag <- mermaid_to_dag(mermaid_src)
  dag$set_start_node("Check")

  # A
  res_a <- dag$run(initial_state = list(choice = "good"))
  expect_true("NodeA" %in% names(res_a$results))
  expect_equal(res_a$results$NodeA$status, "success")
  expect_null(res_a$results$NodeB$status)

  # B
  dag_b <- mermaid_to_dag(mermaid_src)
  dag_b$set_start_node("Check")
  res_b <- dag_b$run(initial_state = list(choice = "bad"))
  expect_true("NodeB" %in% names(res_b$results))
  expect_equal(res_b$results$NodeB$status, "success")
  expect_null(res_b$results$NodeA$status)
})

test_that("Declarative test:logic_id labels in Mermaid work", {
  register_logic("my_custom_test", function(res) {
    identical(res$output, "SECRET")
  })

  mermaid_src <- '
  graph TD
    Check["Checker"]
    Check -- "test:my_custom_test" --> SecretNode["Secret"]
    Check --> FailNode["Fail"]
  '

  dag <- mermaid_to_dag(mermaid_src)
  dag$set_start_node("Check")
  dag$nodes$Check$logic_fn <- function(s) {
    if (s$get("pass") == TRUE) list(output = "SECRET") else list(output = "NOPE")
  }

  res_pass <- dag$run(initial_state = list(pass = TRUE))
  expect_true("SecretNode" %in% names(res_pass$results))
  expect_equal(res_pass$results$SecretNode$status, "success")

  res_fail <- dag$run(initial_state = list(pass = FALSE))
  expect_true("FailNode" %in% names(res_fail$results))
  expect_null(res_fail$results$SecretNode$status)
})

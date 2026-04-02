library(testthat)

test_that("AgentBashNode computes correctly", {
  skip_on_os("windows")
  node <- AgentBashNode$new("bash_node", script = "echo 'Hello World'")
  res <- node$run(state = AgentState$new())
  expect_true(res$success)
  expect_equal(trimws(res$output), "Hello World")
})

test_that("AgentBashNode handles failure correctly", {
  skip_on_os("windows")
  node <- AgentBashNode$new("fail_bash", script = "exit 1")
  res <- node$run(state = AgentState$new())
  expect_false(res$success)
  expect_equal(res$status_code, 1)
})

test_that("AgentBashNode isolates to working_dir", {
  skip_on_os("windows")
  dir <- tempdir()
  node <- AgentBashNode$new("pwd_node", script = "pwd")
  res <- node$run(state = AgentState$new(), working_dir = dir)

  # Ensure the output contains the tempdir path
  expect_true(grepl("var/folders", trimws(res$output), ignore.case = TRUE) || grepl(basename(dir), trimws(res$output)))
})

test_that("AgentPythonNode (system2) computes correctly", {
  py_script <- "
import sys
import json
print('Python System2 OK')
with open(sys.argv[1], 'r') as f:
    state = json.load(f)
print('Input: ' + str(state['val']))
"

  node <- AgentPythonNode$new("py_sys_node", script = py_script, engine = "system2")
  state <- AgentState$new()
  state$set("val", 42)
  res <- node$run(state = state)

  expect_true(res$success)
  expect_true(grepl("Python System2 OK", res$output))
  expect_true(grepl("Input: 42", res$output))
})

test_that("AgentPythonNode (reticulate) computes correctly", {
  skip_if_not_installed("reticulate")

  py_script <- "
result = state_r['val'] * 2
print('Python Reticulate OK')
"
  node <- AgentPythonNode$new("py_ret_node", script = py_script, engine = "reticulate")
  state <- AgentState$new()
  state$set("val", 50)

  res <- node$run(state = state)
  expect_true(res$success)
  expect_equal(res$result, 100)
})

# <!-- APAF Bioinformatics | test-node_languages.R | Approved | 2026-03-29 -->

test_that("AgentPythonNode (reticulate) handles failure correctly", {
  skip_if_not_installed("reticulate")

  py_script <- "
# This will cause a runtime error
result = state_r['val'] / 0
print('Python Reticulate OK')
"
  node <- AgentPythonNode$new("py_ret_fail", script = py_script, engine = "reticulate")
  state <- AgentState$new()
  state$set("val", 50)

  res <- node$run(state = state)
  expect_false(res$success)
  expect_true(is.character(res$error))
  expect_true(nchar(res$error) > 0)
})

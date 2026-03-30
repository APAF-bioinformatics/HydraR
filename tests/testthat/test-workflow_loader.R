library(testthat)

# ==============================================================
# Tests for load_workflow() and 3-tier logic resolution
# ==============================================================

test_that("load_workflow() loads valid YAML and registers components", {
  yaml_file <- tempfile(fileext = ".yml")
  content <- '
graph: |
  graph TD
    A["Agent"] --> B["Logic"]
roles:
  test_concierge: "You are a travel expert."
logic:
  test_simple_logic: "list(status = \'success\', output = \'hello\')"
initial_state:
  city: "Sydney"
'
  writeLines(content, yaml_file)

  wf <- load_workflow(yaml_file)

  # Check returned structure
  expect_equal(wf$graph, "graph TD\n  A[\"Agent\"] --> B[\"Logic\"]\n")
  expect_equal(wf$initial_state$city, "Sydney")

  # Check registry population
  expect_equal(get_role("test_concierge"), "You are a travel expert.")

  # Check logic resolution
  fn <- get_logic("test_simple_logic")
  expect_true(is.function(fn))

  # Execute logic
  res <- fn(NULL)
  expect_equal(res$output, "hello")

  unlink(yaml_file)
})

test_that("resolve_logic_pattern handles Tier 1: External File", {
  logic_file <- tempfile(fileext = ".R")
  writeLines("function(state) { list(status = 'success', output = 'from_file') }", logic_file)

  fn <- resolve_logic_pattern(logic_file)
  expect_true(is.function(fn))
  expect_equal(fn(NULL)$output, "from_file")

  unlink(logic_file)
})

test_that("resolve_logic_pattern handles Tier 2: Existing Function", {
  # 1. Internal registry
  register_logic("my_internal_fn", function(s) "internal")
  fn1 <- resolve_logic_pattern("my_internal_fn")
  expect_equal(fn1(NULL), "internal")

  # 2. Global environment / Package
  test_global_fn <- function(s) "global"
  # Note: In testthat, we might need to assign to global env explicitly if parent.frame doesn't see it
  assign("test_global_fn", test_global_fn, envir = .GlobalEnv)

  fn2 <- resolve_logic_pattern("test_global_fn")
  expect_equal(fn2(NULL), "global")

  rm("test_global_fn", envir = .GlobalEnv)
})

test_that("resolve_logic_pattern handles Tier 3: Anonymous Code", {
  code <- "state$get('val') * 2"
  fn <- resolve_logic_pattern(code)

  mock_state <- R6::R6Class("MockState", public = list(get = function(x) 10))$new()
  expect_equal(fn(mock_state), 20)
})

test_that("load_workflow() errors on missing file or bad format", {
  expect_error(load_workflow("nonexistent.yml"), "not found")

  bad_file <- tempfile(fileext = ".txt")
  writeLines("some content", bad_file)
  expect_error(load_workflow(bad_file), "Unsupported workflow format")
  unlink(bad_file)
})

test_that("validate_workflow_schema warns on unknown keys", {
  data <- list(graph = "...", unknown_key = 123)
  expect_warning(validate_workflow_schema(data), "Unknown top-level keys")
})

test_that("Tier 3 code evaluation has access to 'state'", {
  # This is critical for the "zero-R-code" snippets
  fn <- resolve_logic_pattern("sprintf('Hello %s', state$get('name'))")

  mock_state <- R6::R6Class("MockState", public = list(get = function(x) "World"))$new()
  expect_equal(fn(mock_state), "Hello World")
})

# <!-- APAF Bioinformatics | test-workflow_loader.R | Approved | 2026-03-30 -->

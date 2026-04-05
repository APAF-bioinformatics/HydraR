library(testthat)
library(HydraR)

# ==============================================================
# Tests for load_workflow() and 3-tier logic resolution
# ==============================================================

test_that("load_workflow() loads valid YAML and registers components", {
  yaml_file <- tempfile(fileext = ".yml")

  # Provide logic as a file to resolve it securely
  logic_file <- tempfile(fileext = ".R")
  writeLines("function(state) { list(status = 'success', output = 'hello') }", logic_file)

  # Register a predefined function for logic instead of raw code string
  register_logic("test_simple_logic", function(state) {
    list(status = "success", output = "hello")
  })

  # Use double quotes and escape backslashes for the path
  path_str <- gsub("\\\\", "/", logic_file)

  content <- sprintf('
graph: |
  graph TD
    A["Agent"] --> B["Logic"]
roles:
  test_concierge: "You are a travel expert."
logic:
  test_simple_logic_ref: "%s"
initial_state:
  city: "Sydney"
', path_str)
  writeLines(content, yaml_file)

  wf <- load_workflow(yaml_file)

  # Check returned structure
  expect_equal(wf$graph, "graph TD\n  A[\"Agent\"] --> B[\"Logic\"]\n")
  expect_equal(wf$initial_state$city, "Sydney")

  # Check registry population
  expect_equal(get_role("test_concierge"), "You are a travel expert.")

  # Check logic resolution
  fn <- get_logic("test_simple_logic_ref")
  expect_true(is.function(fn))

  # Execute logic
  res <- fn(NULL)
  expect_equal(res$output, "hello")

  unlink(yaml_file)
  unlink(logic_file)
})

test_that("resolve_logic_pattern handles Tier 1: External File", {
  logic_file <- tempfile(fileext = ".R")
  writeLines("function(state) { list(status = 'success', output = 'from_file') }", logic_file)

  fn <- HydraR:::resolve_logic_pattern(logic_file)
  expect_true(is.function(fn))
  expect_equal(fn(NULL)$output, "from_file")

  unlink(logic_file)
})

test_that("resolve_logic_pattern handles Tier 2: Existing Function", {
  # 1. Internal registry
  register_logic("my_internal_fn", function(s) "internal")
  fn1 <- HydraR:::resolve_logic_pattern("my_internal_fn")
  expect_equal(fn1(NULL), "internal")

  # 2. Global environment / Package
  test_global_fn <- function(s) "global"
  # Note: In testthat, we might need to assign to global env explicitly if parent.frame doesn't see it
  assign("test_global_fn", test_global_fn, envir = .GlobalEnv)

  fn2 <- HydraR:::resolve_logic_pattern("test_global_fn")
  expect_equal(fn2(NULL), "global")

  rm("test_global_fn", envir = .GlobalEnv)
})

test_that("resolve_logic_pattern throws error for insecure strings", {
  code <- "state$get('val') * 2"
  expect_error(HydraR:::resolve_logic_pattern(code), "Failed to resolve logic pattern securely")
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
  expect_warning(HydraR:::validate_workflow_schema(data), "Unknown top-level keys")
})


# <!-- APAF Bioinformatics | test-workflow_loader.R | Approved | 2026-03-30 -->

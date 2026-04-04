library(testthat)
library(HydraR)
library(withr)

test_that("validate_workflow_file works with a valid YAML", {
  # Create a minimal valid workflow
  tmp_yaml <- tempfile(fileext = ".yml")
  yaml_content <- "
graph: |
  graph TD
    A[Start] --> B[End]
roles:
  dummy: 'test'
"
  writeLines(yaml_content, tmp_yaml)
  on.exit(unlink(tmp_yaml))

  expect_true(validate_workflow_file(tmp_yaml))
})

test_that("validate_workflow_file throws error on invalid schema", {
  tmp_yaml <- tempfile(fileext = ".yml")
  # Invalid schema (not a list at top level)
  writeLines("- item1\n- item2", tmp_yaml)
  on.exit(unlink(tmp_yaml))

  expect_error(validate_workflow_file(tmp_yaml), "Workflow data must be a top-level list/object.")
})

test_that("validate_workflow_file catches topology sync errors", {
  tmp_yaml <- tempfile(fileext = ".yml")
  # Mermaid has A --> B, but YAML defines conditional edge to C
  # Use a registered function (reducer_append) to pass Tier 1.5 check
  yaml_content <- "
graph: |
  graph TD
    A --> B
conditional_edges:
  A:
    test: 'reducer_append'
    if_true: 'C'
"
  writeLines(yaml_content, tmp_yaml)
  on.exit(unlink(tmp_yaml))

  expect_error(validate_workflow_file(tmp_yaml), "no matching arrow \\(-->\\) exists in the Mermaid graph")
})

test_that("render_workflow_file returns a DiagrammeR widget", {
  skip_if_not_installed("DiagrammeR")

  tmp_yaml <- tempfile(fileext = ".yml")
  writeLines("graph: |\n  graph TD\n    A --> B", tmp_yaml)
  on.exit(unlink(tmp_yaml))

  res <- render_workflow_file(tmp_yaml)
  expect_s3_class(res, "htmlwidget")
  expect_s3_class(res, "DiagrammeR")
})

test_that("render_workflow_file handles export formats", {
  skip_if_not_installed("DiagrammeR")
  skip_if_not_installed("DiagrammeRsvg")
  skip_if_not_installed("rsvg")

  tmp_yaml <- tempfile(fileext = ".yml")
  writeLines("graph: |\n  graph TD\n    A --> B", tmp_yaml)

  tmp_png <- tempfile(fileext = ".png")
  tmp_svg <- tempfile(fileext = ".svg")

  on.exit({
    unlink(tmp_yaml)
    unlink(tmp_png)
    unlink(tmp_svg)
  })

  expect_invisible(render_workflow_file(tmp_yaml, output_file = tmp_png))
  expect_true(file.exists(tmp_png))
  expect_gt(file.size(tmp_png), 0)

  expect_invisible(render_workflow_file(tmp_yaml, output_file = tmp_svg))
  expect_true(file.exists(tmp_svg))
  expect_gt(file.size(tmp_svg), 0)
})

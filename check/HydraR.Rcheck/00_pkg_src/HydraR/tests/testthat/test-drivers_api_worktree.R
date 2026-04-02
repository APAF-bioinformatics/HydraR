library(testthat)
library(HydraR)
library(withr)

test_that("OpenAIDriver respects working_dir during call", {
  tmp_dir <- normalizePath(withr::local_tempdir())

  # Mock driver to check environment
  MockDriver <- R6::R6Class("MockDriver",
    inherit = OpenAIDriver,
    public = list(
      call = function(...) {
        handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr
        handler(self$working_dir, {
          getwd()
        })
      }
    )
  )

  driver <- MockDriver$new(id = "test_mock", working_dir = tmp_dir)
  expect_equal(normalizePath(driver$call("test")), tmp_dir)
})

test_that("AnthropicDriver respects working_dir during call", {
  tmp_dir <- normalizePath(withr::local_tempdir())

  MockDriver <- R6::R6Class("MockDriver",
    inherit = AnthropicDriver,
    public = list(
      call = function(...) {
        handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr
        handler(self$working_dir, {
          getwd()
        })
      }
    )
  )

  driver <- MockDriver$new(id = "test_mock", working_dir = tmp_dir)
  expect_equal(normalizePath(driver$call("test")), tmp_dir)
})

test_that("GeminiAPIDriver respects working_dir during call", {
  tmp_dir <- normalizePath(withr::local_tempdir())

  MockDriver <- R6::R6Class("MockDriver",
    inherit = GeminiAPIDriver,
    public = list(
      call = function(...) {
        handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr
        handler(self$working_dir, {
          getwd()
        })
      }
    )
  )

  driver <- MockDriver$new(id = "test_mock", working_dir = tmp_dir)
  expect_equal(normalizePath(driver$call("test")), tmp_dir)
})

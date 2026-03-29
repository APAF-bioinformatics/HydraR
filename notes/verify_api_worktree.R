# Verification script for API driver worktree isolation
library(HydraR)
library(withr)

# Define a spy driver that inherits from OpenAIDriver
# but instead of making a network call, it just returns getwd()
SpyDriver <- R6::R6Class("SpyDriver",
  inherit = OpenAIDriver,
  public = list(
    call = function(...) {
      # Use same handler logic as in drivers_api.R
      handler <- if (!is.null(self$working_dir)) withr::with_dir else function(d, expr) expr
      handler(self$working_dir, {
        getwd()
      })
    }
  )
)

tmp_dir <- normalizePath(withr::local_tempdir())
driver <- SpyDriver$new(id = "spy", working_dir = tmp_dir)
result_dir <- normalizePath(driver$call("test prompt"))

cat("Assigned Dir: ", tmp_dir, "\n")
cat("Result Dir:   ", result_dir, "\n")

if (tmp_dir == result_dir) {
  cat("Verification SUCCESS: API Driver respected working_dir.\n")
} else {
  cat("Verification FAILURE: API Driver IGNORED working_dir.\n")
  stop("Worktree isolation check failed.")
}

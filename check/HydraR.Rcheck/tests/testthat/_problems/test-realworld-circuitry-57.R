# Extracted from test-realworld-circuitry.R:57

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "HydraR", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
library(testthat)
library(HydraR)

# test -------------------------------------------------------------------------
skip_if_not(
    nzchar(Sys.which("gemini")),
    message = "gemini CLI not found on PATH — skipping real-world test."
  )
skip_if_not(
    nzchar(Sys.getenv("GEMINI_API_KEY")),
    message = "GEMINI_API_KEY not set — skipping real-world test."
  )
register_logic("gen_fruit", function(state) {
    driver <- GeminiCLIDriver$new()
    raw <- driver$call("Name exactly one tropical fruit. Reply with ONLY the fruit name, nothing else.")
    fruit <- trimws(raw)
    list(status = "success", output = list(fruit_name = fruit))
  })
register_logic("translate_fruit", function(state) {
    fruit <- state$get("fruit_name")
    if (is.null(fruit) || !nzchar(fruit)) stop("fruit_name not found in state")
    driver <- GeminiCLIDriver$new()
    raw <- driver$call(sprintf("Translate '%s' to French. Reply with ONLY the French word.", fruit))
    french <- trimws(raw)
    list(status = "success", output = list(french_name = french))
  })
mermaid_src <- '
  graph TD
    Gen["GenerateFruit | type=logic | logic_id=gen_fruit"]
    Translate["TranslateFruit | type=logic | logic_id=translate_fruit"]
    Gen --> Translate
  '
dag <- mermaid_to_dag(mermaid_src)
dag$set_start_node("Gen")
res <- dag$run(initial_state = list())
expect_equal(res$status, "completed")
expect_false(is.null(res$results$Gen))
expect_false(is.null(res$results$Translate))
fruit <- res$state$get("fruit_name")
french <- res$state$get("french_name")
expect_true(is.character(fruit) && nzchar(fruit),
    info = sprintf("fruit_name was: '%s'", paste(fruit, collapse = ""))
  )

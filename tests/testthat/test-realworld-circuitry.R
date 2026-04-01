library(testthat)
library(HydraR)

# Real-world integration test: requires `gemini` CLI and API key
test_that("Gemini CLI: 2-node fruit translation pipeline", {
  skip_if_not(
    nzchar(Sys.which("gemini")),
    message = "gemini CLI not found on PATH — skipping real-world test."
  )
  skip_if_not(
    nzchar(Sys.getenv("GEMINI_API_KEY")),
    message = "GEMINI_API_KEY not set — skipping real-world test."
  )

  # Node 1: Generate a fruit name via logic that calls the driver
  register_logic("gen_fruit", function(state) {
    driver <- GeminiCLIDriver$new()
    raw <- driver$call("Name exactly one tropical fruit. Reply with ONLY the fruit name, nothing else.")
    fruit <- trimws(raw)
    list(status = "success", output = list(fruit_name = fruit))
  })

  # Node 2: Translate to French
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

  # Verify execution completed
  expect_equal(res$status, "completed")

  # Verify both nodes ran
  expect_false(is.null(res$results$Gen))
  expect_false(is.null(res$results$Translate))

  # Verify outputs are non-empty strings (LLM responses)
  fruit <- res$state$get("fruit_name")
  french <- res$state$get("french_name")
  expect_true(is.character(fruit) && nzchar(fruit),
    info = sprintf("fruit_name was: '%s'", paste(fruit, collapse = ""))
  )
  expect_true(is.character(french) && nzchar(french),
    info = sprintf("french_name was: '%s'", paste(french, collapse = ""))
  )

  cat(sprintf("[Real-world] %s -> %s\n", fruit, french))
})

# <!-- APAF Bioinformatics | test-realworld-circuitry.R | Approved | 2026-04-01 -->

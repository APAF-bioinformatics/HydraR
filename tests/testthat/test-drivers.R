library(testthat)

test_that("extract_r_code_advanced correctly extracts R code blocks", {
  # 1. Standard markdown r block
  raw1 <- "Here is your code:\n```r\nx <- 1\ny <- 2\n```\nEnjoy!"
  expect_equal(extract_r_code_advanced(raw1), "x <- 1\ny <- 2")

  # 2. Case indifference
  raw2 <- "```R\nx <- 1\n```"
  expect_equal(extract_r_code_advanced(raw2), "x <- 1")

  # 3. No fence fallback heuristic
  raw3 <- "x <- 1\nlibrary(dplyr)"
  expect_equal(extract_r_code_advanced(raw3), "x <- 1\nlibrary(dplyr)")

  # 4. Empty string
  expect_equal(extract_r_code_advanced(""), "")
})

test_that("GeminiCLIDriver invokes gemini CLI and captures output", {
  skip_on_os("windows")
  withr::with_tempdir({
    # Create fake gemini executable
    fake_cli <- file.path(getwd(), "gemini")
    cli_script <- c(
      "#!/bin/bash",
      "echo \"$*\" > last_args.txt",
      "echo 'Success Output'"
    )
    writeLines(cli_script, fake_cli)
    Sys.chmod(fake_cli, "0755")

    # Prepend this temp dir to PATH so system2("gemini") executes our fake CLI
    withr::with_path(getwd(), {
      driver <- GeminiCLIDriver$new(model = "test-model")
      output <- driver$call("Hello!", model = "model-override")

      expect_equal(trimws(output), "Success Output")

      # Verify CLI was called with correct args
      args <- readLines("last_args.txt")
      expect_match(args, "--model model-override")
      expect_match(args, "-p -")
    })
  })
})

test_that("OllamaDriver invokes ollama CLI via stdin", {
  skip_on_os("windows")
  withr::with_tempdir({
    fake_cli <- file.path(getwd(), "ollama")
    cli_script <- c(
      "#!/bin/bash",
      "echo \"$*\" > last_args.txt",
      "cat /dev/stdin > last_stdin.txt",
      "echo 'Llama Response'"
    )
    writeLines(cli_script, fake_cli)
    Sys.chmod(fake_cli, "0755")

    withr::with_path(getwd(), {
      driver <- OllamaDriver$new(model = "llama-99b")
      output <- driver$call("Tell me a story.")

      expect_equal(trimws(output), "Llama Response")

      # Verify CLI was called with correct args
      args <- readLines("last_args.txt")
      expect_match(args, "run llama-99b")

      # Verify stdin was correctly passed
      # Note: For Ollama, the full prompt was sprintf("System: %s\n\nUser: %s", self$role, input_text)
      # But wait, driver$call in our implementation just passes the raw prompt.
      stdin_content <- readLines("last_stdin.txt")
      expect_equal(stdin_content, "Tell me a story.")
    })
  })
})

# <!-- APAF Bioinformatics | test-drivers.R | Approved | 2026-03-29 -->

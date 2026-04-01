lines <- readLines("tests/testthat/test-drivers_api.R")

openai_err_test <- c(
  "",
  "test_that(\"OpenAIDriver handles API errors gracefully\", {",
  "  withr::with_envvar(list(OPENAI_API_KEY = \"test_key\"), {",
  "    drv <- OpenAIDriver$new()",
  "    httr2::with_mocked_responses(",
  "      function(req) httr2::response(status_code = 500),",
  "      {",
  "        expect_error(drv$call(\"Hello\"), \"OpenAI API request failed\")",
  "      }",
  "    )",
  "  })",
  "})"
)

anthropic_err_test <- c(
  "",
  "test_that(\"AnthropicDriver handles API errors gracefully\", {",
  "  withr::with_envvar(list(ANTHROPIC_API_KEY = \"test_key\"), {",
  "    drv <- AnthropicDriver$new()",
  "    httr2::with_mocked_responses(",
  "      function(req) httr2::response(status_code = 500),",
  "      {",
  "        expect_error(drv$call(\"Hello\"), \"Anthropic API request failed\")",
  "      }",
  "    )",
  "  })",
  "})"
)

gemini_err_test <- c(
  "",
  "test_that(\"GeminiAPIDriver handles API errors gracefully\", {",
  "  withr::with_envvar(list(GOOGLE_API_KEY = \"test_key\"), {",
  "    drv <- GeminiAPIDriver$new()",
  "    httr2::with_mocked_responses(",
  "      function(req) httr2::response(status_code = 500),",
  "      {",
  "        expect_error(drv$call(\"Hello\"), \"Gemini API request failed\")",
  "      }",
  "    )",
  "  })",
  "})"
)

# Insert after OpenAIDriver success test
idx <- grep("test_that\\(\"OpenAIDriver correctly formats requests and parses response\"", lines)
end_idx <- grep("^\\}\\)$", lines)
open_end <- end_idx[end_idx > idx[1]][1]

lines <- c(lines[1:open_end], openai_err_test, lines[(open_end+1):length(lines)])

# Re-evaluate indices
idx <- grep("test_that\\(\"AnthropicDriver correctly formats requests and parses response\"", lines)
end_idx <- grep("^\\}\\)$", lines)
anth_end <- end_idx[end_idx > idx[1]][1]

lines <- c(lines[1:anth_end], anthropic_err_test, lines[(anth_end+1):length(lines)])

# Re-evaluate indices
idx <- grep("test_that\\(\"GeminiAPIDriver correctly formats requests and parses response\"", lines)
end_idx <- grep("^\\}\\)$", lines)
gem_end <- end_idx[end_idx > idx[1]][1]

lines <- c(lines[1:gem_end], gemini_err_test, lines[(gem_end+1):length(lines)])

writeLines(lines, "tests/testthat/test-drivers_api.R")

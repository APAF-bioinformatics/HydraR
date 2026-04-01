lines <- readLines("R/drivers_api.R")

# Update OpenAIDriver
idx <- grep("resp <- httr2::req_perform\\(req\\)", lines)
lines[idx[1]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"OpenAI API request failed: %s\", e$message))\n        })"

# Update AnthropicDriver
idx <- grep("resp <- httr2::req_perform\\(req\\)", lines)
lines[idx[2]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"Anthropic API request failed: %s\", e$message))\n        })"

# Update GeminiAPIDriver
idx <- grep("resp <- httr2::req_perform\\(req\\)", lines)
lines[idx[3]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"Gemini API request failed: %s\", e$message))\n        })"

writeLines(lines, "R/drivers_api.R")

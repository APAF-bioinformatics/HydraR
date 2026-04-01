lines <- readLines("R/drivers_api.R")

# find the indices of httr2::req_perform
matches <- grep("resp <- httr2::req_perform\\(req\\)", lines)

lines[matches[1]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"OpenAI API request failed: %s\", e$message))\n        })"

lines[matches[2]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"Anthropic API request failed: %s\", e$message))\n        })"

lines[matches[3]] <- "        resp <- tryCatch({\n          httr2::req_perform(req)\n        }, error = function(e) {\n          stop(sprintf(\"Gemini API request failed: %s\", e$message))\n        })"

writeLines(lines, "R/drivers_api.R")

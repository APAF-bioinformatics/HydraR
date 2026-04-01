lines <- readLines("R/drivers_api.R")

# Line 140 is Anthropic, change it
idx1 <- 140
lines[idx1] <- "          stop(sprintf(\"Anthropic API request failed: %s\", e$message))"

# Line 208 is Gemini, change it
idx2 <- 208
lines[idx2] <- "          stop(sprintf(\"Gemini API request failed: %s\", e$message))"

writeLines(lines, "R/drivers_api.R")

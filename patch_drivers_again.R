lines <- readLines("R/drivers_api.R")
cat("Read", length(lines), "lines\n")

# Re-read and fix
idx1 <- grep("OpenAI API request failed", lines)
idx2 <- grep("Anthropic API request failed", lines)
idx3 <- grep("Gemini API request failed", lines)
print(c(idx1, idx2, idx3))

# Wait, `idx <- grep("resp <- httr2::req_perform\\(req\\)", lines)` was replaced, so we can't grep that again.
# Let's inspect drivers_api.R

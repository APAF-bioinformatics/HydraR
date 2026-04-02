
library(HydraR)
# Test a direct call to see if the key is working and what models are available
res <- system2("gemini", args = "models list", stdout = TRUE, stderr = TRUE)
cat("Available Models:\n")
print(res)

# Try a very simple prompt to verify connectivity
tryCatch({
  driver <- GeminiCLIDriver$new(model = "gemini-1.5-flash")
  out <- driver$call("Identify yourself briefly.")
  cat("\nResponse from gemini-1.5-flash:\n")
  print(out)
}, error = function(e) {
  cat("\nError with gemini-1.5-flash:\n")
  print(e$message)
})

tryCatch({
  driver <- GeminiCLIDriver$new(model = "gemini-2.0-flash")
  out <- driver$call("Identify yourself briefly.")
  cat("\nResponse from gemini-2.0-flash:\n")
  print(out)
}, error = function(e) {
  cat("\nError with gemini-2.0-flash:\n")
  print(e$message)
})

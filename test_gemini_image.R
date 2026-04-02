# Test Script for GeminiImageDriver
# This script tests the image generation driver in isolation.

# Prepare environment
library(httr2)
library(R6)
library(purrr)
library(digest)
library(base64enc)

# Source necessary files
source("R/utils.R")
source("R/driver.R")
source("R/drivers_api.R")

# Check for API Key
api_key <- Sys.getenv("GOOGLE_API_KEY")
if (api_key == "") {
  stop("GOOGLE_API_KEY not found in environment. Please set it before running this test.")
}

message("Testing GeminiImageDriver with model: gemini-3.1-flash-image-preview")

# Initialize Driver
# Using a local test directory for images
test_dir <- "test_images"
if (!dir.exists(test_dir)) dir.create(test_dir)

driver <- GeminiImageDriver$new(
  id = "test_gen",
  model = "gemini-3.1-flash-image-preview",
  output_dir = test_dir,
  aspect_ratio = "16:9"
)

# Test Prompt
test_prompt <- "A futuristic cyberpunk robot eating noodles in a neon-lit Hong Kong alleyway. High resolution, detailed textures."

tryCatch({
  message("Calling Gemini API for image generation...")
  img_path <- driver$call(test_prompt, cli_opts = list(filename = "test_robot.png"))
  
  if (file.exists(img_path)) {
    message("SUCCESS: Image generated and saved to: ", img_path)
    message("File size: ", file.size(img_path), " bytes.")
  } else {
    message("FAILURE: img_path returned but file does not exist: ", img_path)
  }
}, error = function(e) {
  message("CRITICAL ERROR during image generation: ", e$message)
  # Print more details if it's an httr2 error
  if (inherits(e, "httr2_http")) {
     resp <- attr(e, "resp")
     if (!is.null(resp)) {
       message("Response Body:")
       print(httr2::resp_body_json(resp))
     }
  }
})

render_mermaid <- function(mmd_text, output_file) {
  # Base64 encode the Mermaid text
  temp_mmd <- tempfile(fileext = ".mmd")
  writeLines(mmd_text, temp_mmd)
  
  # Standard Base64 encoding on Mac
  b64_output <- system(sprintf("base64 -i %s", temp_mmd), intern = TRUE)
  b64_str <- paste(b64_output, collapse = "")
  
  # Construct URL for Mermaid.ink (PNG)
  url <- paste0("https://mermaid.ink/img/", b64_str)
  
  # Download the file
  success <- tryCatch({
    download.file(url, destfile = output_file, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) {
    message("Error downloading: ", e$message)
    FALSE
  })
  
  if (success) {
    message(paste("Saved:", output_file))
  }
}

# Ensure figures directory exists
dir.create("paper/figures", showWarnings = FALSE, recursive = TRUE)

# 1. Travel Workflow
travel_mmd <- "graph LR
  Planner[\"Travel Planner | type=llm | role_id=travel_concierge\"]
  Validator[\"Constraint Auditor | type=logic | logic_id=validate_constraints\"]
  ImageGate[\"Image Gate | type=logic | logic_id=check_image_status\"]
  ImageGenerator[\"Image Generator | type=logic | logic_id=generate_and_save_images\"]
  TemplateManager[\"Template Provider | type=logic | logic_id=provide_template\"]
  PamphletFormatter[\"Pamphlet Formatter | type=logic | logic_id=format_pamphlet\"]
  Finalizer[\"Itinerary Saver | type=logic | logic_id=save_itinerary\"]

  Planner --> Validator
  Validator -- \"fail\" --> Planner
  Validator -- \"pass\" --> ImageGate
  ImageGate --> ImageGenerator
  ImageGate --> TemplateManager
  ImageGenerator --> TemplateManager
  TemplateManager --> PamphletFormatter
  PamphletFormatter --> Finalizer"

render_mermaid(travel_mmd, "paper/figures/travel_workflow.png")

# 2. Sorting Workflow
sorting_mmd <- "graph LR
    bubble[\"Bubble Agent | type=llm | role_id=bubble\"]
    quick[\"Quick Agent | type=llm | role_id=quick\"]
    merge[\"Merge Agent | type=llm | role_id=merge\"]
    merger[\"Merge Harmonizer | type=merge\"]
    benchmark[\"Benchmark | type=logic | logic_id=run_benchmark\"]

    bubble --> merger
    quick --> merger
    merge --> merger
    merger --> benchmark"

render_mermaid(sorting_mmd, "paper/figures/sorting_workflow.png")

# 3. Fault-Tolerant Pipeline
fault_mmd <- "graph LR
  Step1[\"Initialization\"] --> Step2[\"Risky Logic\"]
  Step2[\"Risky Logic\"] --> Step3[\"Conclusion\"]"

render_mermaid(fault_mmd, "paper/figures/fault_workflow.png")

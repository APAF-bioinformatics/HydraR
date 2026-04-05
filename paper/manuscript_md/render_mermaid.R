render_mermaid <- function(mmd_text, output_file) {
  # Use Kroki POST API for robust rendering (no length limits, no encoding issues)
  url <- "https://kroki.io/mermaid/png"

  temp_mmd <- tempfile(fileext = ".mmd")
  cat(mmd_text, file = temp_mmd)

  # POST the raw text to Kroki
  success <- tryCatch(
    {
      system(sprintf("curl -s -X POST -H \"Content-Type: text/plain\" --data-binary @%s %s --output %s", temp_mmd, url, output_file))
      file.exists(output_file) && file.size(output_file) > 1000
    },
    error = function(e) {
      message("Error downloading: ", e$message)
      FALSE
    }
  )

  if (success) {
    message(paste("Saved:", output_file))
  } else {
    if (file.exists(output_file)) {
      msg <- tryCatch(readLines(output_file, n = 1, warn = FALSE), error = function(e) "Binary data or error msg")
      message(paste("Failed to save:", output_file, "-", msg))
      unlink(output_file)
    } else {
      message(paste("Failed to save:", output_file))
    }
  }
}

# Ensure figures directory exists
dir.create("paper/figures", showWarnings = FALSE, recursive = TRUE)

# 1. Travel Workflow
travel_mmd <- "flowchart LR
Planner[Travel<br/>Planner]
Validator[Constraint<br/>Auditor]
ImageGate[Image<br/>Gate]
ImageGenerator[Image<br/>Generator]
TemplateManager[Template<br/>Provider]
PamphletFormatter[Pamphlet<br/>Formatter]
Finalizer[Itinerary<br/>Saver]

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
sorting_mmd <- "flowchart LR
bubble[Bubble Agent]
quick[Quick Agent]
merge[Merge Agent]
merger[Merge Harmonizer]
benchmark[Benchmark]

bubble --> merger
quick --> merger
merge --> merger
merger --> benchmark"

render_mermaid(sorting_mmd, "paper/figures/sorting_workflow.png")

# 3. Fault-Tolerant Pipeline
fault_mmd <- "flowchart LR
Step1[Initialization] --> Step2[Risky Logic]
Step2[Risky Logic] --> Step3[Conclusion]"

render_mermaid(fault_mmd, "paper/figures/fault_workflow.png")

# 4. Travel Workflow (Subgraph Layout)
travel_subgraph_mmd <- 'flowchart TD
subgraph P1 ["Planning Phase"]
    direction LR
    Planner[Travel Planner]
    Validator[Constraint Auditor]
    Planner --> Validator
    Validator -- "fail" --> Planner
end
subgraph P2 ["Generation Phase"]
    direction LR
    ImageGate[Image Gate]
    ImageGenerator[Image Generator]
    ImageGate --> ImageGenerator
end
subgraph P3 ["Assembly Phase"]
    direction LR
    TemplateManager[Template Provider]
    PamphletFormatter[Pamphlet Formatter]
    Finalizer[Itinerary Saver]
    TemplateManager --> PamphletFormatter
    PamphletFormatter --> Finalizer
end
Validator -- "pass" --> ImageGate
ImageGate --> TemplateManager
ImageGenerator --> TemplateManager'

render_mermaid(travel_subgraph_mmd, "paper/figures/travel_workflow_subgraph.png")

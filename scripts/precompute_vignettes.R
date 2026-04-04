# ==============================================================
# APAF Bioinformatics | HydraR | precompute_vignettes.R
# Purpose:     Pre-computes expensive vignettes into static Rmd.
# ==============================================================

library(knitr)
library(purrr)

vignettes_dir <- "vignettes"
# List .Rmd.orig files
orig_files <- list.files(vignettes_dir, pattern = "\\.Rmd\\.orig$", full.names = TRUE)

purrr::walk(orig_files, function(orig_path) {
  dest_path <- gsub("\\.orig$", "", orig_path)
  message(sprintf("Pre-computing: %s -> %s", orig_path, dest_path))
  
  # 1. Knit to static Rmd
  # This executes the code and captures output
  knitr::knit(orig_path, output = dest_path, quiet = TRUE, envir = new.env())
  
  # 2. Post-processing: Set eval = FALSE in the generated file
  # This ensures that when CRAN/CI builds the package, it doesn't re-run the code.
  content <- readLines(dest_path)
  
  # Replace global eval setting if present, or add it to setup chunk
  # We find the first knitr::opts_chunk$set and update it
  setup_idx <- grep("knitr::opts_chunk\\$set", content)
  if (length(setup_idx) > 0) {
    # Check if eval is already there
    if (grep("eval =", content[setup_idx[1]])) {
      content[setup_idx[1]] <- gsub("eval = [^,)]+", "eval = FALSE", content[setup_idx[1]])
    } else {
      content[setup_idx[1]] <- gsub("knitr::opts_chunk\\$set\\(", "knitr::opts_chunk\\$set(eval = FALSE, ", content[setup_idx[1]])
    }
  }
  
  writeLines(content, dest_path)
})

message("Pre-computation complete! Please review the generated .Rmd files.")

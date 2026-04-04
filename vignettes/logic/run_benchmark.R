# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        run_benchmark.R
# Author:      APAF Agentic Workflow
# Purpose:     Sorting algorithm benchmark logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  # Ensure current branch is up to date (usually main)
  curr_branch <- system("git branch --show-current", intern = TRUE)
  message(sprintf("[Benchmark] Running on branch: %s", curr_branch))

  # Source all generated files
  files <- list.files(pattern = "_sort.R")
  message(sprintf("[Benchmark] Found %d algorithm files: %s",
    length(files), paste(files, collapse = ", ")))

  # Use tryCatch to skip corrupted files (e.g. from LLM noise)
  purrr::walk(files, function(f) {
    tryCatch(source(f), error = function(e) {
      warning(sprintf("[Benchmark] Failed to source %s: %s", f, e$message))
    })
  })

  # Benchmark parameters
  n_elements <- 1000
  n_trials <- 5
  methods <- c("bubble", "quick", "merge")

  results_df <- purrr::map_df(methods, function(m) {
    func_name <- paste0(m, "_sort")
    if (!exists(func_name)) return(NULL)
    func <- get(func_name)

    times <- purrr::map_dbl(seq_len(n_trials), function(i) {
      test_data <- rnorm(n_elements)
      start <- Sys.time()
      func(test_data)
      as.numeric(difftime(Sys.time(), start, units = "secs"))
    })

    data.frame(method = m, time = times)
  })

  list(status = "success", output = results_df)
}

# <!-- APAF Bioinformatics | run_benchmark.R | Approved | 2026-04-03 -->

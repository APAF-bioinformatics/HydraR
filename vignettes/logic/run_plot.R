# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        run_plot.R
# Author:      APAF Agentic Workflow
# Purpose:     Sorting algorithm visualization logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  df <- state$get("benchmark")
  if (is.null(df) || nrow(df) == 0) {
    return(list(status = "failed", output = NULL, error = "No benchmark data found."))
  }

  # Suppress graphics device warnings
  pdf(NULL)
  on.exit(if (dev.cur() > 1) dev.off())

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$method, y = .data$time, fill = .data$method
  )) +
    ggplot2::geom_boxplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = "Sorting Algorithm Performance",
      y = "Time (seconds)", x = "Algorithm"
    )

  p2 <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$method, y = .data$time, fill = .data$method
  )) +
    ggplot2::geom_violin() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = "Sorting Algorithm Performance",
      y = "Time (seconds)", x = "Algorithm"
    )


  pdf(file = "sorting_benchmark.pdf")
  print(p)
  dev.off()

  pdf(file = "sorting_benchmark_violin_plot.pdf")
  print(p2)
  dev.off()


  # PROACTIVE EXPORT: Copy the PDF back to the base directory if specified in the state
  output_dir <- state$get("output_dir")
  if (!is.null(output_dir) && dir.exists(output_dir)) {
    success <- file.copy("sorting_benchmark.pdf", file.path(output_dir, "sorting_benchmark.pdf"), overwrite = TRUE)
    if (success) {
      message(sprintf("[run_plot] Successfully exported plot to: %s", output_dir))
    } else {
      warning(sprintf("[run_plot] Failed to export plot to: %s", output_dir))
    }

    success <- file.copy("sorting_benchmark_violin_plot.pdf", file.path(output_dir, "sorting_benchmark_violin_plot.pdf"), overwrite = TRUE)
    if (success) {
      message(sprintf("[run_plot] Successfully exported plot to: %s", output_dir))
    } else {
      warning(sprintf("[run_plot] Failed to export plot to: %s", output_dir))
    }
  }

  list(status = "success", output = "Plot rendered and exported.")
}

# <!-- APAF Bioinformatics | run_plot.R | Approved | 2026-04-03 -->

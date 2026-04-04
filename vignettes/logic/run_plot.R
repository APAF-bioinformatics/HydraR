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

  pdf(file = "sorting_benchmark.pdf")
  print(p)
  dev.off()
  list(status = "success", output = "Plot rendered.")
}

# <!-- APAF Bioinformatics | run_plot.R | Approved | 2026-04-03 -->

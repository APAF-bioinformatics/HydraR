lines <- readLines("tests/testthat/test-sorting_benchmark.R")
new_lines <- c()
for (line in lines) {
  if (grepl("test_that\\(\"Parallel Sorting Benchmark workflow executes successfully\"", line)) {
    new_lines <- c(new_lines, line)
    new_lines <- c(new_lines, "  skip_if_not_installed(\"HydraR\")")
  } else {
    new_lines <- c(new_lines, line)
  }
}
writeLines(new_lines, "tests/testthat/test-sorting_benchmark.R")

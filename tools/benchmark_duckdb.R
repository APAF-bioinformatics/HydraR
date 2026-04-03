source("R/message_log.R")

db_path <- tempfile(fileext = ".duckdb")

logger <- DuckDBMessageLog$new(db_path = db_path)
logger$log(list(from = "A", to = "B", timestamp = Sys.time(), content = list(data = 1)))

cat("Benchmarking current get_all()...\n")
start_time <- Sys.time()
for (i in 1:100) {
  logger$get_all()
}
end_time <- Sys.time()
cat("Current get_all() took: ", as.numeric(end_time - start_time), "seconds\n")

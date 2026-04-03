temp_db <- "vignettes/travel_booking_peek.duckdb"
file.copy("vignettes/travel_booking.duckdb", temp_db, overwrite = TRUE)

con <- DBI::dbConnect(duckdb::duckdb(), temp_db, read_only = TRUE)
tables <- DBI::dbListTables(con)
cat("Tables in DuckDB: ", paste(tables, collapse = ", "), "\n")

for (tbl in tables) {
  cat("\n--- Table: ", tbl, "---\n")
  res <- DBI::dbGetQuery(con, sprintf("SELECT * FROM %s LIMIT 1", tbl))
  print(head(res))
}

DBI::dbDisconnect(con)
file.remove(temp_db)

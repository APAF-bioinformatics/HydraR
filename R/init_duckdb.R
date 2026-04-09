#' Initialize Bot History DuckDB
#'
#' @description
#' Connects to the master DuckDB for telemetry and logs.
#' Follows APAF Bioinformatics mandatory pattern for database persistence.
#'
#' @param read_only Logical. If TRUE, connects in read-only mode.
#' @return A DBIConnection object.
#' @examples
#' \dontrun{
#' init_bot_history()
#' }
#' @export
init_bot_history <- function(read_only = FALSE) {
  db_path <- "~/.gemini/memory/bot_history.duckdb"

  # Ensure path expansion for home directory
  db_path <- path.expand(db_path)

  # Check if directory exists, if not, create it
  db_dir <- dirname(db_path)
  if (!dir.exists(db_dir)) {
    dir.create(db_dir, recursive = TRUE)
  }

  con <- DBI::dbConnect(duckdb::duckdb(), db_path, read_only = read_only)
  return(con)
}

# <!-- APAF Bioinformatics | init_duckdb.R | Approved | 2026-04-02 -->

# Initialize Bot History DuckDB

Connects to the master DuckDB for telemetry and logs. Follows APAF
Bioinformatics mandatory pattern for database persistence.

## Usage

``` r
init_bot_history(read_only = FALSE)
```

## Arguments

- read_only:

  Logical. If TRUE, connects in read-only mode.

## Value

A DBIConnection object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect to the master bot history for auditing
con <- init_bot_history(read_only = TRUE)

# Use DBI to query the execution logs
library(DBI)
dbListTables(con)
dbDisconnect(con)
} # }
```

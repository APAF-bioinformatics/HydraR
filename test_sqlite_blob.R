library(DBI)
con <- dbConnect(RSQLite::SQLite(), ":memory:")
dbExecute(con, "CREATE TABLE t (id VARCHAR PRIMARY KEY, data BLOB)")

my_list <- list(a = 1, b = function(x) x + 1)
my_raw <- serialize(my_list, NULL)

# Test 1
tryCatch({
  dbExecute(con, "INSERT INTO t (id, data) VALUES (?, ?)", params = list("1", list(my_raw)))
  print("Test 1 success")
}, error = function(e) print(e))

res <- dbGetQuery(con, "SELECT data FROM t WHERE id = '1'")
print(typeof(res$data[[1]]))
val <- unserialize(res$data[[1]])
print(val$b(5))

dbDisconnect(con)

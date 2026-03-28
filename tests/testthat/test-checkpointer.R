library(testthat)

test_that("MemorySaver checkpointer works", {
    saver <- MemorySaver$new()
    state <- AgentState$new(list(key = "value"))
    
    thread_id <- "thread1"
    saver$put(thread_id, state)
    
    restored <- saver$get(thread_id)
    expect_equal(restored$get("key"), "value")
    
    # Check non-existent thread
    expect_null(saver$get("nonexistent"))
})

test_that("DuckDBSaver checkpointer works", {
    tmp_db <- tempfile(fileext = ".db")
    saver <- DuckDBSaver$new(db_path = tmp_db)
    
    state <- AgentState$new(list(x = 10, y = 20))
    thread_id <- "thread2"
    
    # Initial put
    saver$put(thread_id, state)
    
    # Get back
    restored <- saver$get(thread_id)
    expect_equal(restored$get("x"), 10)
    expect_equal(restored$get("y"), 20)
    
    # Update and put again
    state$set("x", 100)
    saver$put(thread_id, state)
    
    restored2 <- saver$get(thread_id)
    expect_equal(restored2$get("x"), 100)
    
    # Clean up
    DBI::dbDisconnect(saver$con, shutdown = TRUE)
})

# <!-- APAF Bioinformatics | test-checkpointer.R | Approved | 2026-03-29 -->

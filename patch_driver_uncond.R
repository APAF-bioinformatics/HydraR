--- R/driver.R
+++ R/driver.R
@@ -73,11 +73,8 @@
     #' @param args Character vector. Command arguments.
     #' @param ... Additional arguments passed to system2.
     #' @return Result of system2 call.
     exec_in_dir = function(command, args, ...) {
-      if (.Platform$OS.type == "windows") {
-        args <- shQuote(args)
-      }
+      args <- shQuote(args)
       res <- if (!is.null(self$working_dir)) {
         withr::with_dir(self$working_dir, {
           system2(command, args, ...)

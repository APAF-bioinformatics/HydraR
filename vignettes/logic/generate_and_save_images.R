# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        generate_and_save_images.R
# Author:      APAF Agentic Workflow
# Purpose:     Image generation logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  tryCatch({
    message("DEBUG: generate_and_save_images logic entry")
    targets <- state$get("targets")
    message("DEBUG: targets from state: ", paste(targets %||% "NULL", collapse = ", "))
    
    if (is.null(targets) || length(targets) == 0) {
      message("DEBUG: No targets found, exiting early.")
      return(list(status = "SUCCESS", output = list(image_prompts = list())))
    }

    # Initialize driver and options
    aspect_ratio <- state$get("aspect_ratio") %||% "1:1"
    driver <- resolve_default_driver("gemini_image")
    driver$model_name <- "gemini-3.1-flash-image-preview"
    
    # Directory-aware pathing
    driver$output_dir <- if (dir.exists("vignettes")) "vignettes/images" else "images"
    
    # Per-item generation with detailed error capture
    results <- purrr::imap(targets, function(filename, idx) {
      tryCatch({
        # Rate-limit guard: pause between API calls
        if (idx > 1) Sys.sleep(3)
        loc <- tools::file_path_sans_ext(filename)
        loc <- gsub("_", " ", loc)
        prompt <- sprintf("Professional travel photography of %s, Hong Kong. Vibrant, high-resolution, wide landscape format.", loc)
        message("DEBUG: Generating image for: ", filename)
        
        img_path <- driver$call(prompt, cli_opts = list(
          filename = filename
        ))
        list(success = TRUE, filename = filename, prompt = prompt, path = img_path)
      }, error = function(e) {
        msg <- if (inherits(e, "error")) e$message else as.character(e)
        message("DEBUG: Failed image generation for ", filename, ": ", msg)
        list(success = FALSE, filename = filename, error = msg)
      })
    })
    
    # Check for any failures
    failures <- purrr::keep(results, function(x) !x$success)
    if (length(failures) > 0) {
      err_msg <- paste(purrr::map_chr(failures, function(x) sprintf("%s: %s", x$filename, x$error)), collapse = "; ")
      stop(sprintf("One or more images failed generation: %s", err_msg))
    }

    # Harmonize prompts for state
    env <- new.env(parent = emptyenv())
    env$prompts <- list()
    purrr::walk(results, function(res) {
      env$prompts[[res$filename]] <- res$prompt
    })

    list(status = "SUCCESS", output = list(image_prompts = env$prompts))
  }, error = function(e) {
    msg <- if (inherits(e, "error")) e$message else as.character(e)
    message("ERROR in generate_and_save_images: ", msg)
    list(status = "failed", output = NULL, error = msg)
  })
}

# <!-- APAF Bioinformatics | generate_and_save_images.R | Approved | 2026-04-03 -->

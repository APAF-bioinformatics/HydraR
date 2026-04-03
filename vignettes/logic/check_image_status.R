# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        check_image_status.R
# Author:      APAF Agentic Workflow
# Purpose:     Image availability check logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  force <- state$get("force_regenerate_images") %||% FALSE
  
  # Diagnostic: Print current WD to help identify pathing mismatches
  curr_wd <- getwd()
  message("DEBUG: ImageGate calling from CWD: ", curr_wd)
  
  # Use the most specific path available
  possible_dirs <- c("vignettes/images", "images")
  exists_dirs <- purrr::map_lgl(possible_dirs, dir.exists)
  img_dir <- if (any(exists_dirs)) possible_dirs[which(exists_dirs)[1]] else "vignettes/images"
  
  required <- c("victoria_peak.jpg", "man_mo_temple.jpg", "tsim_sha_tsui.jpg", "temple_street.jpg", "star_ferry.jpg")
  
  missing <- required[!purrr::map_lgl(required, function(f) file.exists(file.path(img_dir, f)))]
  
  if (force || length(missing) > 0) {
    targets <- if (force) required else missing
    message("DEBUG: ImageGate found missing images in ", img_dir, ": ", paste(targets, collapse = ", "))
    list(status = "SUCCESS", output = list(needs_generation = TRUE, targets = targets))
  } else {
    message("All images found in: ", img_dir)
    list(status = "SUCCESS", output = list(needs_generation = FALSE))
  }
}

# <!-- APAF Bioinformatics | check_image_status.R | Approved | 2026-04-03 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        skill_discovery.R
# Author:      APAF Agentic Workflow
# Purpose:     Automated discovery and registration of external package skills
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Discover and Register External Package Skills
#'
#' @description
#' Scans all installed R packages for a \code{hydrar/manifest.yaml} file and
#' registers any defined functions into the HydraR Logic Registry. This
#' enables a "plugin" ecosystem where any R package can export agentic skills.
#'
#' @param quiet Logical. Whether to suppress informative messages.
#'
#' @return A character vector of names of successfully registered skills (invisibly).
#'
#' @export
discover_package_skills <- function(quiet = FALSE) {
  installed_pkgs <- as.data.frame(utils::installed.packages())
  env <- new.env(parent = emptyenv())
  env$registered_count <- 0
  env$all_registered <- c()

  if (!quiet) message("HydraR: Scanning installed packages for agentic skills...")

  purrr::walk(installed_pkgs$Package, function(pkg) {
    manifest_path <- system.file("hydrar", "manifest.yaml", package = pkg)
    if (manifest_path == "") {
      manifest_path <- system.file("hydrar", "manifest.json", package = pkg)
    }

    if (manifest_path != "") {
      tryCatch({
        skills <- .parse_and_register_manifest(manifest_path, pkg)
        env$registered_count <- env$registered_count + length(skills)
        env$all_registered <- c(env$all_registered, skills)
      }, error = function(e) {
        if (!quiet) warning(sprintf("Failed to process HydraR manifest for package '%s': %s", pkg, e$message))
      })
    }
  })

  if (!quiet && env$registered_count > 0) {
    message(sprintf("HydraR: Successfully registered %d external skills from across the ecosystem.", env$registered_count))
  }

  invisible(env$all_registered)
}

#' Internal parser for manifest files
#' @keywords internal
.parse_and_register_manifest <- function(path, pkg) {
  ext <- tolower(tools::file_ext(path))
  data <- if (ext %in% c("yml", "yaml")) {
    yaml::read_yaml(path)
  } else {
    jsonlite::read_json(path, simplifyVector = FALSE)
  }

  if (is.null(data$skills)) return(character(0))

  env <- new.env(parent = emptyenv())
  env$registered <- c()
  purrr::walk(data$skills, function(skill) {
    name <- skill$id
    fn_name <- skill[["function"]]
    
    # Attempt to resolve the function from the package
    fn <- tryCatch(utils::getFromNamespace(fn_name, pkg), error = function(e) NULL)
    
    if (is.function(fn)) {
      register_logic(name, fn)
      env$registered <- c(env$registered, name)
    }
  })
  
  env$registered
}

# --- APAF Bioinformatics | skill_discovery.R | Approved | 2026-04-16 ---

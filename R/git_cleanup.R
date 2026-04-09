# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        git_cleanup.R
# Author:      APAF Agentic Workflow
# Purpose:     GitHub Branch Cleanup Utility (Maintenance)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Helper to check if a branch is stale
#' @param b String. Branch name
#' @param repo_root String. Path to the git repository
#' @param jules_bot_email String. Email of bot.
#' @param threshold_hours Numeric. Inactivity threshold.
#' @param now Integer. Current Unix timestamp.
#' @param verbose Logical. If TRUE, logs details.
#' @return Logical TRUE if branch should be deleted.
#' @keywords internal
.is_branch_stale <- function(b, repo_root, jules_bot_email, threshold_hours, now, verbose) {
  log_info <- system2("git", c("-C", shQuote(repo_root), "log", "-n", "1", "--format='%ae|%ct'", shQuote(paste0("origin/", b))), stdout = TRUE)
  if (length(log_info) == 0) {
    return(FALSE)
  }
  parts <- strsplit(log_info, "\\|")[[1]]
  author_email <- parts[1]
  last_commit_ts <- as.integer(parts[2])
  age_hours <- (now - last_commit_ts) / 3600
  is_merged <- system2("git", c("-C", repo_root, "branch", "-r", "--merged", "origin/main"), stdout = TRUE)
  is_merged <- any(grepl(paste0("origin/", b, "$"), is_merged))
  if (is_merged) {
    if (verbose) message(sprintf("[MERGED]  %s (Merged into main)", b))
    return(TRUE)
  }
  if (author_email == jules_bot_email && age_hours > threshold_hours) {
    if (verbose) message(sprintf("[STALE]   %s (Jules branch, inactive for %.1f hours)", b, age_hours))
    return(TRUE)
  }
  return(FALSE)
}

#' Cleanup Stale GitHub Branches
#'
#' @description
#' Identifies and optionally deletes stale remote branches on GitHub.
#' Specifically targets branches authored by 'google-labs-jules[bot]'
#' that have been inactive beyond a specified threshold, or any branch
#' already merged into the main branch.
#'
#' @param repo_root String. Path to the git repository. Defaults to `getwd()`.
#' @param threshold_hours Numeric. Inactivity threshold for Jules's branches (hours). Defaults to 24.
#' @param dry_run Logical. If TRUE (default), identifies candidates but does not perform deletion.
#' @param verbose Logical. If TRUE, prints detailed status messages.
#'
#' @return A character vector of branches identified for deletion.
#'
#' @importFrom purrr walk map_lgl
#' @examples
#' \dontrun{
#' # 1. Identify stale branches without deleting (Dry Run)
#' stale_branches <- cleanup_jules_branches(dry_run = TRUE)
#'
#' # 2. Perform aggressive cleanup of stale bot branches (> 48 hours)
#' cleanup_jules_branches(
#'   threshold_hours = 48,
#'   dry_run = FALSE,
#'   verbose = TRUE
#' )
#' }
#' @export
cleanup_jules_branches <- function(repo_root = getwd(),
                                   threshold_hours = 24,
                                   dry_run = TRUE,
                                   verbose = TRUE) {
  if (verbose) message("--- HydraR Branch Cleanup Utility ---")

  # 1. Fetch latest remote state
  res_fetch <- system2("git", c("-C", repo_root, "fetch", "--all", "--prune"), stdout = FALSE, stderr = FALSE)
  if (res_fetch != 0) {
    stop(sprintf("Git fetch failed for repository at '%s'. Ensure it is a valid git repository.", repo_root))
  }

  # 2. List remote branches
  branches_raw <- system2("git", c("-C", repo_root, "branch", "-r"), stdout = TRUE)
  if (length(attributes(branches_raw)$status) > 0 && attributes(branches_raw)$status != 0) {
    stop("Failed to list remote branches.")
  }

  # Filter out origin/HEAD and protected branches
  branches <- grep("origin/(main|gh-pages|HEAD)", branches_raw, invert = TRUE, value = TRUE)
  branches <- trimws(gsub("origin/", "", branches))

  if (length(branches) == 0) {
    if (verbose) message("No candidate branches found.")
    return(character(0))
  }

  # 3. Identify Cleanup Candidates
  jules_bot_email <- "161369871+google-labs-jules[bot]@users.noreply.github.com"
  now <- as.integer(Sys.time())

  to_delete <- purrr::map_lgl(branches, function(b) {
    .is_branch_stale(b, repo_root, jules_bot_email, threshold_hours, now, verbose)
  })

  candidates <- branches[to_delete]

  # 4. Perform Deletion
  if (length(candidates) > 0) {
    if (dry_run) {
      if (verbose) message(sprintf("\nDRY RUN: %d branches marked for deletion (not executed).", length(candidates)))
    } else {
      if (verbose) message(sprintf("\nDELETING: %d remote branches...", length(candidates)))
      purrr::walk(candidates, function(b) {
        system2("git", c("-C", repo_root, "push", "origin", "--delete", b), stdout = FALSE, stderr = FALSE)
        if (verbose) message(sprintf("  - [Deleted] %s", b))
      })
    }
  } else {
    if (verbose) message("No stale branches identified for cleanup.")
  }

  return(invisible(candidates))
}

# <!-- APAF Bioinformatics | git_cleanup.R | Approved | 2026-04-01 -->

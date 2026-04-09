lines <- readLines("R/git_cleanup.R")

new_fn <- c(
"#' Helper to check if a branch is stale",
"#' @param b String. Branch name",
"#' @param repo_root String. Path to the git repository",
"#' @param jules_bot_email String. Email of bot.",
"#' @param threshold_hours Numeric. Inactivity threshold.",
"#' @param now Integer. Current Unix timestamp.",
"#' @param verbose Logical. If TRUE, logs details.",
"#' @return Logical TRUE if branch should be deleted.",
"#' @keywords internal",
".is_branch_stale <- function(b, repo_root, jules_bot_email, threshold_hours, now, verbose) {",
"  log_info <- system2(\"git\", c(\"-C\", shQuote(repo_root), \"log\", \"-n\", \"1\", \"--format='%ae|%ct'\", shQuote(paste0(\"origin/\", b))), stdout = TRUE)",
"  if (length(log_info) == 0) return(FALSE)",
"  parts <- strsplit(log_info, \"\\\\|\")[[1]]",
"  author_email <- parts[1]",
"  last_commit_ts <- as.integer(parts[2])",
"  age_hours <- (now - last_commit_ts) / 3600",
"  is_merged <- system2(\"git\", c(\"-C\", repo_root, \"branch\", \"-r\", \"--merged\", \"origin/main\"), stdout = TRUE)",
"  is_merged <- any(grepl(paste0(\"origin/\", b, \"$\"), is_merged))",
"  if (is_merged) {",
"    if (verbose) message(sprintf(\"[MERGED]  %s (Merged into main)\", b))",
"    return(TRUE)",
"  }",
"  if (author_email == jules_bot_email && age_hours > threshold_hours) {",
"    if (verbose) message(sprintf(\"[STALE]   %s (Jules branch, inactive for %.1f hours)\", b, age_hours))",
"    return(TRUE)",
"  }",
"  return(FALSE)",
"}",
""
)

# Insert the helper before cleanup_jules_branches
insert_idx <- grep("^cleanup_jules_branches <- function", lines) - 1 # actually we need to preserve roxygen, so find the start of the roxygen block for cleanup_jules_branches
# Instead, insert at top right after license
insert_idx <- 8

lines <- c(lines[1:insert_idx], new_fn, lines[(insert_idx+1):length(lines)])

# Now replace the body inside cleanup_jules_branches
import_idx <- grep("^  to_delete <- purrr::map_lgl\\(branches, function\\(b\\) \\{", lines)
end_idx <- grep("^  \\}\\)$", lines)
end_idx <- end_idx[end_idx > import_idx][1]

new_call <- c(
"  to_delete <- purrr::map_lgl(branches, function(b) {",
"    .is_branch_stale(b, repo_root, jules_bot_email, threshold_hours, now, verbose)",
"  })"
)

lines <- c(lines[1:(import_idx-1)], new_call, lines[(end_idx+1):length(lines)])

writeLines(lines, "R/git_cleanup.R")

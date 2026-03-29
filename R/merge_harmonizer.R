# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        merge_harmonizer.R
# Author:      APAF Agentic Workflow
# Purpose:     Logic Node for Merging Parallel Git Worktrees
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Create a Merge Harmonizer Node
#'
#' @description
#' Factory function to create an AgentLogicNode that merges parallel git branches
#' back into the base branch.
#'
#' @param id String. Node identifier.
#' @param strategy String. "sequential" or "octopus".
#' @param conflict_resolver ConflictResolver. Optional custom resolver.
#' @return An `AgentLogicNode` R6 object.
#' @examples
#' \dontrun{
#' node <- create_merge_harmonizer(id = "merger", strategy = "sequential")
#' }
#' @export
create_merge_harmonizer <- function(id = "merge_harmonizer",
                                    strategy = "sequential",
                                    conflict_resolver = NULL) {
  logic_fn <- function(state) {
    # 1. Retrieve WorktreeManager
    wt_manager <- state$get("__worktree_manager__")
    if (is.null(wt_manager)) {
      return(list(status = "skip", output = "No active worktree manager found. Nothing to merge."))
    }

    repo_root <- wt_manager$repo_root
    base_branch <- wt_manager$base_branch

    # 2. Identify branches to merge
    # We look at all worktrees registered in the manager, excluding ourselves
    node_ids <- setdiff(names(wt_manager$worktrees), id)
    if (length(node_ids) == 0) {
      return(list(status = "success", output = "No branches to merge."))
    }

    cat(sprintf("[%s] Starting merge of %d branches into %s...\n", id, length(node_ids), base_branch))

    # 3. Perform Merges
    merge_results <- list()
    conflicts <- list()

    # Ensure we are on the base branch in the main repo
    system2("git", c("-C", shQuote(repo_root), "checkout", shQuote(base_branch)), stdout = FALSE, stderr = FALSE)

    purrr::walk(node_ids, function(node_id) {
      branch <- wt_manager$get_branch(node_id)
      if (is.null(branch)) {
        return()
      }

      cat(sprintf("   [%s] Merging branch: %s\n", id, branch))

      # Execute git merge <branch>
      res <- system2("git", c("-C", shQuote(repo_root), "merge", "--no-ff", shQuote(branch)),
        stdout = TRUE, stderr = TRUE
      )

      exit_code <- attr(res, "status") %||% 0L
      if (exit_code != 0L) {
        cat(sprintf("   [%s] WARNING: Conflict merging %s\n", id, branch))

        # Conflict Resolution logic
        resolved <- FALSE
        if (!is.null(conflict_resolver)) {
          # Get list of conflicting files
          conf_files <- system2("git", c("-C", shQuote(repo_root), "diff", "--name-only", "--diff-filter=U"), stdout = TRUE)

          res_logic <- conflict_resolver$resolve(repo_root, branch, base_branch, conf_files)
          if (res_logic$status == "RESOLVED") {
            resolved <- TRUE
          } else {
            conflicts[[node_id]] <<- list(branch = branch, detail = res_logic)
          }
        } else {
          conflicts[[node_id]] <<- list(branch = branch, detail = "Manual merge required")
        }

        if (!resolved) {
          # Abort the merge to keep repo clean for other branches
          system2("git", c("-C", shQuote(repo_root), "merge", "--abort"), stdout = FALSE, stderr = FALSE)
        }
      } else {
        # Success
        merge_results[[node_id]] <<- "merged"
        # Cleanup the branch now that it is merged
        wt_manager$delete_branch(node_id)
      }
    })

    # 4. Final Status
    if (length(conflicts) > 0) {
      return(list(
        status = "pause",
        output = list(
          merge_results = merge_results,
          conflicts = conflicts
        )
      ))
    }

    return(list(
      status = "success",
      output = list(merge_results = merge_results)
    ))
  }

  AgentLogicNode$new(id = id, logic_fn = logic_fn, label = "Merge Harmonizer")
}

#' <!-- APAF Bioinformatics | merge_harmonizer.R | Approved | 2026-03-29 -->

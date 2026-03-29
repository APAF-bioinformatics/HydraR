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
#' @return AgentLogicNode.
#' @export
create_merge_harmonizer <- function(id = "merge_harmonizer", 
                                     strategy = "sequential",
                                     conflict_policy = "llm_fix",
                                     llm_driver = NULL) {
  
  logic_fn = function(state) {
    # 1. Retrieve WorktreeManager
    wt_manager <- state$get("__worktree_manager__")
    if (is.null(wt_manager)) {
      return(list(status = "skip", output = "No active worktree manager found. Nothing to merge."))
    }
    
    repo_root <- wt_manager$repo_root
    base_branch <- wt_manager$base_branch
    worktrees <- wt_manager$worktrees
    
    if (length(worktrees) == 0) {
      return(list(status = "success", output = "No active worktrees to merge."))
    }
    
    if (!wt_manager$is_repo_clean()) {
      return(list(status = "failed", output = "Cannot harmonize: repository has uncommitted changes. Please commit or stash them first."))
    }
    
    # Ensure we are on the base branch in the main repo
    cat(sprintf("   [%s] Checking out base branch: %s\n", id, base_branch))
    system2("git", c("-C", shQuote(repo_root), "checkout", shQuote(base_branch)), 
            stdout = FALSE, stderr = FALSE)
    
    cat(sprintf("   [%s] Harmonizing %d parallel branches...\n", id, length(worktrees)))
    
    merge_results <- list()
    conflicts <- list()
    
    # 2. Perform Merges
    if (strategy == "sequential") {
      purrr::walk(names(worktrees), function(node_id) {
        branch <- worktrees[[node_id]]$branch
        cat(sprintf("   [%s] Merging branch: %s\n", id, branch))
        
        # git merge --no-ff <branch>
        res <- system2("git", c("-C", shQuote(repo_root), "merge", "--no-ff", shQuote(branch)), 
                        stdout = TRUE, stderr = TRUE)
        
        exit_code <- attr(res, "status") %||% 0L
        if (exit_code != 0L) {
          cat(sprintf("   [%s] WARNING: Conflict merging %s\n", id, branch))
          
          # Conflict Resolution Policy
          resolved <- FALSE
          if (conflict_policy == "llm_fix" && !is.null(llm_driver)) {
            cat(sprintf("   [%s] Attempting LLM Conflict FIX for: %s\n", id, branch))
            prompt <- sprintf("I encountered a git merge conflict while merging branch '%s' into '%s'. 
                              The conflict details are: \n%s\n
                              Please provide a series of R commands to resolve this conflict (e.g., using system2('git', ...)). 
                              The output should only contain R code blocks.", 
                              branch, base_branch, paste(res, collapse = "\n"))
            llm_res <- llm_driver$call(prompt)
            # We extract and run the code
            r_code <- extract_r_code_advanced(llm_res$output)
            if (!is.null(r_code) && nzchar(r_code)) {
              exec_res <- tryCatch(eval(parse(text = r_code)), error = function(e) e)
              if (!inherits(exec_res, "error")) {
                # Verify if resolved
                check_res <- system2("git", c("-C", shQuote(repo_root), "status", "--porcelain"), stdout = TRUE)
                if (length(grep("^U", check_res)) == 0) resolved <- TRUE
              }
            }
          }

          if (!resolved) {
            conflicts[[node_id]] <<- list(branch = branch, detail = res)
          } else {
            cat(sprintf("   [%s] Successfully resolved conflict via LLM for: %s\n", id, branch))
            wt_manager$remove_branch(node_id)
          }
        } else {
          # Success! 
          wt_manager$remove_branch(node_id)
        }
        
        merge_results[[node_id]] <<- list(
          branch = branch,
          status = if (node_id %in% names(conflicts)) "conflict" else "merged"
        )
      })
    } else if (strategy == "octopus") {
      # Octopus merge: merge all at once
      branches <- purrr::map_chr(worktrees, "branch")
      res <- system2("git", c("-C", shQuote(repo_root), "merge", "--no-ff", shQuote(branches)), 
                      stdout = TRUE, stderr = TRUE)
      
      exit_code <- attr(res, "status") %||% 0L
      if (exit_code != 0L) {
        return(list(status = "failed", output = "Octopus merge failed. Use sequential strategy for conflict resolution.", error = paste(res, collapse = "\n")))
      }
      merge_results <- list(strategy = "octopus", branches = branches)
      # Cleanup all branches
      purrr::walk(names(worktrees), function(node_id) wt_manager$remove_branch(node_id))
    }
    
    # 3. Handle Conflicts
    if (length(conflicts) > 0) {
      return(list(
        status = "pause", 
        output = list(merge_results = merge_results, conflicts = conflicts),
        error = "Merge conflicts encountered. LLM Fix failed or Policy set to Manual."
      ))
    }
    
    # 4. Final Cleanup
    wt_manager$cleanup()
    
    return(list(
      status = "success", 
      output = list(merge_results = merge_results)
    ))
  }
  
  AgentLogicNode$new(id = id, logic_fn = logic_fn, label = "Merge Harmonizer")
}

#' <!-- APAF Bioinformatics | merge_harmonizer.R | Approved | 2026-03-29 -->

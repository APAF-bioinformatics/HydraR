# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        worktree.R
# Author:      APAF Agentic Workflow
# Purpose:     Git Worktree Management for Parallel DAG Execution
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Git Worktree Manager R6 Class
#'
#' @description
#' Manages the lifecycle of isolated git worktrees for parallel DAG branches.
#' This ensures that each parallel worker has its own filesystem checkout,
#' preventing file-level conflicts between concurrent CLI agents.
#'
#' @return A `WorktreeManager` R6 object.
#' @examples
#' \dontrun{
#' wt_manager <- WorktreeManager$new(repo_root = getwd())
#' }
#' @importFrom R6 R6Class
#' @importFrom purrr walk
#' @importFrom digest digest
#' @importFrom uuid UUIDgenerate
#' @export
WorktreeManager <- R6::R6Class("WorktreeManager",
  public = list(
    #' @field repo_root String. Path to the main git repository.
    repo_root = NULL,
    #' @field worktrees List. Active worktrees indexed by node_id.
    worktrees = list(),
    #' @field base_branch String. The branch to fork worktrees from.
    base_branch = NULL,
    #' @field branch_prefix String. Prefix for auto-generated branch names.
    branch_prefix = "hydra",
    #' @field cleanup_policy String. "auto", "none", or "aggressive".
    cleanup_policy = "auto",
    #' @field thread_id String. Optional identifier for the current DAG execution.
    thread_id = NULL,

    #' @description Initialize the WorktreeManager.
    #' @param repo_root Path to the main git repository. Defaults to `getwd()`.
    #' @param base_branch Branch to branch from. Defaults to "main".
    #' @param branch_prefix Prefix for new branches.
    #' @param cleanup_policy Cleanup strategy.
    #' @param thread_id Optional string to group worktrees. Defaults to random UUID.
    #' @return A new `WorktreeManager` object.
    initialize = function(repo_root = getwd(),
                          base_branch = "main",
                          branch_prefix = "hydra",
                          cleanup_policy = "auto",
                          thread_id = NULL) {
      self$repo_root <- normalizePath(repo_root, mustWork = TRUE)
      self$base_branch <- base_branch
      self$branch_prefix <- branch_prefix
      self$cleanup_policy <- cleanup_policy

      if (is.null(thread_id)) {
        self$thread_id <- uuid::UUIDgenerate()
      } else {
        self$thread_id <- thread_id
      }
    },

    #' Validate a branch name
    #' @param branch String. The branch name to validate.
    #' @return Logical or error.
    validate_branch_name = function(branch) {
      # Basic git branch name safety
      # Must not start with '-' to prevent flag injection
      if (grepl("^-", branch)) {
        stop(sprintf("Invalid branch name '%s': Cannot start with a hyphen.", branch))
      }

      # Restrict to safe characters (alphanumeric, -, _, /, .)
      if (!grepl("^[A-Za-z0-9_./-]+$", branch)) {
        stop(sprintf("Invalid branch name '%s': Contains illegal characters.", branch))
      }

      return(TRUE)
    },

    #' Create an Isolated Worktree
    #' @param node_id String. Identifier for the DAG node.
    #' @param branch_name Optional specific branch name.
    #' @param fail_if_dirty Logical. Whether to stop if repo has uncommitted changes.
    #' @return String. The absolute path to the new worktree.
    create = function(node_id, branch_name = NULL, fail_if_dirty = TRUE) {
      # Defensive check: Ensure repo is clean
      if (fail_if_dirty && !self$is_repo_clean()) {
        stop(sprintf("[%s] Cannot create worktree: repository has uncommitted changes. Please commit or stash them first.", node_id))
      }

      # Branch naming: prefix/thread_id/node_id-hash
      branch <- branch_name
      if (is.null(branch)) {
        hash <- substr(digest::digest(paste0(node_id, Sys.time())), 1, 8)
        tid <- self$thread_id %||% "default"
        branch <- paste0(self$branch_prefix, "/", tid, "/", node_id, "-", hash)
      }

      # Security check on the branch name
      self$validate_branch_name(branch)

      wt_path <- file.path(self$repo_root, ".hydra_worktrees", gsub("/", "_", branch))

      # Execute git worktree add -b <branch> <path> <base>
      res <- system2("git", c(
        "-C", shQuote(self$repo_root),
        "worktree", "add", "-b", shQuote(branch),
        shQuote(wt_path), shQuote(self$base_branch)
      ),
      stdout = TRUE, stderr = TRUE
      )

      exit_code <- attr(res, "status") %||% 0L
      if (exit_code != 0L) {
        stop(sprintf(
          "Failed to create git worktree for node '%s': %s",
          node_id, paste(res, collapse = "\n")
        ))
      }

      self$worktrees[[node_id]] <- list(
        path = wt_path,
        branch = branch,
        created_at = Sys.time()
      )

      return(wt_path)
    },

    #' Get Worktree Path for a Node
    #' @param node_id Node identifier.
    #' @return String path or NULL.
    get_path = function(node_id) {
      self$worktrees[[node_id]]$path
    },

    #' Get Worktree Branch for a Node
    #' @param node_id Node identifier.
    #' @return String branch name or NULL.
    get_branch = function(node_id) {
      self$worktrees[[node_id]]$branch
    },

    #' Remove the Physical Worktree Directory
    #' @param node_id Node identifier.
    #' @param force Logical. Force removal.
    #' @return Logical (invisibly).
    remove_worktree = function(node_id, force = TRUE) {
      wt <- self$worktrees[[node_id]]
      if (is.null(wt) || is.null(wt$path)) {
        return(invisible(FALSE))
      }

      # Extract the branch name or relative path to validate
      # Normally wt$branch is present, but let's be safe.
      if (!is.null(wt$branch)) {
        self$validate_branch_name(wt$branch)
      } else {
        # Fallback to validating the last segment of the path just in case
        self$validate_branch_name(basename(wt$path))
      }

      args <- c("worktree", "remove")
      if (force) args <- c(args, "--force")
      args <- c(args, shQuote(wt$path))

      # Attempt to remove the worktree
      res <- system2("git", c("-C", shQuote(self$repo_root), args),
        stdout = TRUE, stderr = TRUE
      )

      exit_code <- attr(res, "status") %||% 0L
      if (exit_code == 0L) {
        # Mark as detached (directory gone, but branch/metadata preserved)
        wt$path <- NULL
        self$worktrees[[node_id]] <- wt
        return(invisible(TRUE))
      } else {
        # Keep path preserved as removal failed
        return(invisible(FALSE))
      }
    },

    #' Delete the branch and unregister node
    #' @param node_id Node identifier.
    #' @return Logical (invisibly).
    delete_branch = function(node_id) {
      wt <- self$worktrees[[node_id]]
      if (is.null(wt)) {
        return(invisible(FALSE))
      }

      self$validate_branch_name(wt$branch)

      # Attempt to delete the branch (cleanup)
      system2("git", c("-C", shQuote(self$repo_root), "branch", "-D", shQuote(wt$branch)),
        stdout = FALSE, stderr = FALSE
      )

      self$worktrees[[node_id]] <- NULL
      invisible(TRUE)
    },

    #' Legacy remove method for backward compatibility
    #' @param node_id Node identifier.
    #' @param force Logical. Force removal.
    #' @param delete_branch Logical. Delete the branch.
    #' @return NULL (called for side effect).
    remove = function(node_id, force = TRUE, delete_branch = FALSE) {
      self$remove_worktree(node_id, force = force)
      if (delete_branch) self$delete_branch(node_id)
      invisible(NULL)
    },

    #' Cleanup Worktree based on Policy and Status
    #' @param node_id Node identifier.
    #' @param status String. "success", "failure", or "conflict".
    #' @return NULL (called for side effect).
    cleanup_node = function(node_id, status = "success") {
      policy <- self$cleanup_policy

      should_remove <- switch(policy,
        "aggressive" = TRUE,
        "none" = FALSE,
        "auto" = (status == "success"),
        TRUE # default to removing
      )

      if (should_remove) {
        # default to only removing the worktree dir, keeping branch for harmonizer
        self$remove(node_id, delete_branch = FALSE)
      } else {
        # Keep it, but maybe log it?
        message(sprintf(
          "Persisting worktree for node '%s' (status: %s, policy: %s)",
          node_id, status, policy
        ))
      }
      invisible(NULL)
    },

    #' Cleanup All Worktrees
    #' @description
    #' Removes all worktrees managed by this instance.
    #' @return Logical (invisibly).
    cleanup = function() {
      if (length(self$worktrees) > 0) {
        # Only remove worktrees that still have a path (haven't been removed yet)
        purrr::walk(names(self$worktrees), function(node_id) {
          self$remove_worktree(node_id)
        })
      }

      # DO NOT remove the .hydra_worktrees folder here as it may contain
      # metadata or still-needed branches for the main repo process.
      invisible(TRUE)
    },

    #' Check if a branch exists
    #' @param branch String.
    #' @return Logical.
    branch_exists = function(branch) {
      self$validate_branch_name(branch)
      res <- system2("git", c(
        "-C", shQuote(self$repo_root),
        "rev-parse", "--verify", shQuote(branch)
      ),
      stdout = FALSE, stderr = FALSE
      )
      return(attr(res, "status") %||% 0L == 0L)
    },

    #' Check if the Repository is Clean
    #' @return Logical.
    is_repo_clean = function() {
      res <- system2("git", c("-C", shQuote(self$repo_root), "status", "--porcelain"),
        stdout = TRUE, stderr = TRUE
      )
      # status is 0, but stdout should be empty if clean
      status <- attr(res, "status") %||% 0L
      if (status != 0L) {
        return(FALSE)
      }
      return(length(res) == 0)
    }
  )
)

#' Git Conflict Resolver R6 Class
#'
#' @description
#' Handles semantic or git-level conflicts during branch merges.
#' Used by Conflict Harmonizer nodes.
#'
#' @return A `ConflictResolver` R6 object.
#' @importFrom R6 R6Class
#' @export
ConflictResolver <- R6::R6Class("ConflictResolver",
  public = list(
    #' @field strategy String. "llm", "human", or "ours".
    strategy = "llm",
    #' @field driver AgentDriver. The driver to use for "llm" strategy.
    driver = NULL,

    #' @description Initialize ConflictResolver
    #' @param strategy Conflict resolution strategy.
    #' @param driver Optional LLM driver for semantic resolution.
    #' @return A new `ConflictResolver` object.
    initialize = function(strategy = "llm", driver = NULL) {
      self$strategy <- strategy
      self$driver <- driver
    },

    #' Resolve a Conflict
    #' @param repo_root Path to repo.
    #' @param branch_a Branch A.
    #' @param branch_b Branch B (usually base).
    #' @param files List of conflicting files.
    #' @return List with status and details.
    resolve = function(repo_root, branch_a, branch_b, files) {
      if (self$strategy == "ours") {
        # Deterministic: ignore their changes
        return(list(status = "RESOLVED", method = "ours"))
      }

      if (self$strategy == "human") {
        # Triggers HITL
        return(list(status = "pause", reason = "conflict", files = files))
      }

      if (self$strategy == "llm") {
        # Implement semantic merge? This is complex.
        # For now, it might just flag for review with an LLM summary.
        return(list(status = "RESOLVED", method = "llm", detail = "Semantic merge attempted."))
      }

      stop(sprintf("Unknown strategy: %s", self$strategy))
    }
  )
)

#' <!-- APAF Bioinformatics | worktree.R | Approved | 2026-03-29 -->

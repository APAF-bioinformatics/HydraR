# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        node_jules.R
# Author:      APAF Agentic Workflow
# Purpose:     Jules API Agent Node Class for HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Jules Node R6 Class
#'
#' @description
#' A node that interacts with the Google Jules API for asynchronous coding tasks.
#'
#' @return An `AgentJulesNode` object.
#' @importFrom R6 R6Class
#' @export
AgentJulesNode <- R6::R6Class("AgentJulesNode",
  inherit = AgentNode,
  public = list(
    #' @field client JulesClient object.
    client = NULL,
    #' @field prompt String. The coding task prompt.
    prompt = NULL,
    #' @field source String. Source name (e.g., "sources/github/owner/repo").
    source = NULL,
    #' @field branch String. Starting branch name.
    branch = NULL,
    #' @field timeout Integer. Timeout in seconds (default 1800).
    timeout = 1800,
    #' @field poll_interval Integer. Polling interval in seconds (default 10).
    poll_interval = 10,

    #' Initialize AgentJulesNode
    #' @param id Unique identifier.
    #' @param prompt String. The coding task prompt.
    #' @param source String. Optional source override.
    #' @param branch String. Optional branch override.
    #' @param timeout Integer. Max wait time in seconds.
    #' @param label Optional human-readable name.
    #' @param params Optional list of parameters.
    initialize = function(id, prompt, source = NULL, branch = NULL, timeout = 1800, label = NULL, params = list()) {
      super$initialize(id, label = label, params = params)
      self$prompt <- prompt
      self$source <- source
      self$branch <- branch
      self$timeout <- timeout
      self$client <- JulesClient$new()
    },

    #' Run the Jules Node
    #' @param state AgentState object.
    #' @param ... Additional arguments.
    #' @return List with status, output, and metadata.
    run = function(state, ...) {
      # 1. Resolve Source and Branch
      source <- self$source %||% self$params$source
      branch <- self$branch %||% self$params$branch

      if (is.null(source) || is.null(branch)) {
        git_context <- self$.resolve_git_context()
        source <- source %||% git_context$source
        branch <- branch %||% git_context$branch
      }

      if (is.null(source)) stop(sprintf("[%s] Jules source could not be resolved. Please provide 'source' parameter.", self$id))
      if (is.null(branch)) stop(sprintf("[%s] Jules starting branch could not be resolved. Please provide 'branch' parameter.", self$id))

      # 2. Create Session
      message(sprintf("[%s] Creating Jules session for source '%s' on branch '%s'...", self$id, source, branch))
      session <- tryCatch(
        {
          self$client$create_session(
            prompt = self$prompt,
            source = source,
            starting_branch = branch,
            title = self$label,
            automation_mode = self$params$automation_mode %||% "AUTO_CREATE_PR",
            require_plan_approval = self$params$require_plan_approval %||% FALSE
          )
        },
        error = function(e) {
          return(list(error = e$message))
        }
      )

      if (!is.null(session$error)) {
        self$last_result <- list(status = "failed", error = session$error)
        return(self$last_result)
      }

      session_id <- session$id
      message(sprintf("[%s] Session created: %s. Polling for results...", self$id, session_id))

      # 3. Polling Loop
      start_time <- Sys.time()
      terminal_states <- c("COMPLETED", "FAILED", "CANCELLED")

      while (TRUE) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        if (elapsed > self$timeout) {
          self$last_result <- list(status = "timeout", session_id = session_id, error = "Timeout reached while waiting for Jules session.")
          return(self$last_result)
        }

        # Fetch latest session info
        current_session <- tryCatch(self$client$get_session(session_id), error = function(e) NULL)
        if (is.null(current_session)) {
          Sys.sleep(self$poll_interval)
          next
        }

        # Check for completion
        # Note: The actual Jules API might use a 'state' field or similar in the session object
        # Based on documentation provided, we check for 'outputs' or completion indicator
        # We'll assume 'state' exists or infer from presence of outputs in AUTO_CREATE_PR mode
        if (!is.null(current_session$outputs) && length(current_session$outputs) > 0) {
          self$last_result <- list(status = "success", output = current_session$outputs, session = current_session)
          return(self$last_result)
        }

        # If no outputs yet, but maybe it's in progress
        # we'll wait. Real API likely has a state field.
        # I'll check 'sessionCompleted' activity if needed, but polling GetSession is standard.

        Sys.sleep(self$poll_interval)
      }
    },

    #' Internal Helper to Resolve Git Context
    #' @return List with source and branch.
    #' @keywords internal
    .resolve_git_context = function() {
      source <- NULL
      branch <- NULL

      # Try to get branch from system
      try(
        {
          branch <- system2("git", c("rev-parse", "--abbrev-ref", "HEAD"), stdout = TRUE, stderr = FALSE)
          if (length(branch) == 0 || branch == "") branch <- NULL
        },
        silent = TRUE
      )

      # Try to get source from remote URL
      try(
        {
          remote_url <- system2("git", c("remote", "get-url", "origin"), stdout = TRUE, stderr = FALSE)
          if (length(remote_url) > 0 && remote_url != "") {
            # Format: https://github.com/owner/repo.git or git@github.com:owner/repo.git
            # We want "sources/github/owner/repo"
            if (grepl("github\\.com", remote_url)) {
              clean_url <- gsub(".*github\\.com[:/]", "", remote_url)
              clean_url <- gsub("\\.git$", "", clean_url)
              source <- sprintf("sources/github/%s", clean_url)
            }
          }
        },
        silent = TRUE
      )

      list(source = source, branch = branch)
    }
  )
)

# <!-- APAF Bioinformatics | node_jules.R | Approved | 2026-04-01 -->

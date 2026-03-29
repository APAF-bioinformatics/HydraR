# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        state_restricted.R
# Author:      APAF Agentic Workflow
# Purpose:     Secure Access-Control Wrapper for AgentState
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Restricted State R6 Class
#'
#' @description
#' A security wrapper for AgentState that restricts access based on node_id.
#' Implements "True Privacy" for inter-agent communication.
#'
#' @importFrom R6 R6Class
#' @export
RestrictedState <- R6::R6Class("RestrictedState",
  public = list(
    #' @field state AgentState. The underlying global state.
    state = NULL,
    #' @field node_id String. The ID of the currently executing node.
    node_id = NULL,
    #' @field logger MessageLog. Audit log for communication.
    logger = NULL,

    #' Initialize RestrictedState
    #' @param state AgentState object.
    #' @param node_id String node ID.
    #' @param logger Optional MessageLog object.
    initialize = function(state, node_id, logger = NULL) {
      stopifnot(inherits(state, "AgentState"))
      self$state <- state
      self$node_id <- node_id
      self$logger <- logger
    },

    #' Restricted Get
    #' @param key String.
    #' @param default Default value.
    get = function(key, default = NULL) {
      if (private$.is_forbidden(key)) {
        stop(sprintf("[%s] Access Denied: Cannot read private key '%s'", self$node_id, key))
      }
      self$state$get(key, default = default)
    },

    #' Restricted Set
    #' @param key String.
    #' @param value Any.
    set = function(key, value) {
      if (private$.is_forbidden(key)) {
        stop(sprintf("[%s] Access Denied: Cannot write private key '%s'", self$node_id, key))
      }
      self$state$set(key, value)
      invisible(self)
    },

    #' Forward Update
    #' @param updates List.
    update = function(updates) {
      forbidden_keys <- Filter(private$.is_forbidden, names(updates))
      if (length(forbidden_keys) > 0) {
        stop(sprintf("[%s] Access Denied: Cannot update private keys: %s", self$node_id, paste(forbidden_keys, collapse = ", ")))
      }
      self$state$update(updates)
      invisible(self)
    },

    #' Send Private Message
    #' @param to String. Target node ID.
    #' @param content Any. Message content.
    #' @param ... Additional metadata.
    send_message = function(to, content, ...) {
      inbox_key <- sprintf(".__inbox__%s__", to)
      
      # Prepare message object
      msg <- list(
        from = self$node_id,
        to = to,
        timestamp = Sys.time(),
        content = content,
        ...
      )

      # Append to the recipient's inbox in global state
      current_inbox <- self$state$get(inbox_key, default = list())
      self$state$set(inbox_key, c(current_inbox, list(msg)))

      # Log if logger exists
      if (!is.null(self$logger)) {
        self$logger$log(msg)
      }
      
      invisible(self)
    },

    #' Receive Private Messages
    #' @return List of messages for this node.
    receive_messages = function() {
      inbox_key <- sprintf(".__inbox__%s__", self$node_id)
      self$state$get(inbox_key, default = list())
    },

    #' Clear Own Inbox
    #' @description Removes all messages from the node's own inbox.
    clear_inbox = function() {
      inbox_key <- sprintf(".__inbox__%s__", self$node_id)
      self$state$set(inbox_key, list())
      invisible(self)
    },

    #' Filtered Get All
    #' @return List. All public state variables (no private inboxes).
    get_all = function() {
      all_data <- self$state$get_all()
      # Hide all other inboxes but allow own.
      names <- names(all_data)
      own_inbox_pattern <- sprintf("^\\.__inbox__%s__$", self$node_id)
      
      # Keep keys that are NOT inboxes OR match our own inbox
      visible_keys <- !grepl("^\\.__inbox__", names) | grepl(own_inbox_pattern, names)
      all_data[visible_keys]
    }
  ),
  private = list(
    # Internal: Check if a key is a private inbox of another node
    .is_forbidden = function(key) {
      if (!grepl("^\\.__inbox__", key)) return(FALSE)
      
      target_inbox_pattern <- sprintf("^\\.__inbox__%s__$", self$node_id)
      if (grepl(target_inbox_pattern, key)) return(FALSE)
      
      return(TRUE)
    }
  )
)

# <!-- APAF Bioinformatics | state_restricted.R | Approved | 2026-03-29 -->

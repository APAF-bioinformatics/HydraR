# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        jules_client.R
# Author:      APAF Agentic Workflow
# Purpose:     Low-level R6 Client for Google Jules API
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Jules API Client R6 Class
#'
#' @description
#' Provides a low-level interface to the Google Jules REST API for
#' programmatically creating and managing asynchronous coding tasks.
#'
#' @return A `JulesClient` object.
#' @importFrom R6 R6Class
#' @importFrom httr2 request req_auth_bearer_token req_headers req_body_json req_perform resp_body_json
#' @export
JulesClient <- R6::R6Class("JulesClient",
  public = list(
    #' @field api_base String. Base URL for the Jules API.
    api_base = "https://jules.googleapis.com/v1alpha",

    #' Initialize JulesClient
    #' @return A new `JulesClient` object.
    initialize = function() {
    },

    #' List Available Sources
    #' @return List of sources.
    list_sources = function() {
      req <- self$.request("sources")
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' Create a New Session
    #' @param prompt String. The coding task prompt.
    #' @param source String. Source name (e.g., "sources/github/owner/repo").
    #' @param starting_branch String. Initial branch name.
    #' @param title String. Optional session title.
    #' @param automation_mode String. Default "AUTO_CREATE_PR".
    #' @param require_plan_approval Logical. Default FALSE.
    #' @return List with session details.
    create_session = function(prompt, source, starting_branch = "main", title = NULL, automation_mode = "AUTO_CREATE_PR", require_plan_approval = FALSE) {
      body <- list(
        prompt = prompt,
        sourceContext = list(
          source = source,
          githubRepoContext = list(startingBranch = starting_branch)
        ),
        automationMode = automation_mode,
        requirePlanApproval = require_plan_approval
      )
      if (!is.null(title)) body$title <- title

      req <- self$.request("sessions") |>
        httr2::req_method("POST") |>
        httr2::req_body_json(body)

      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' Get Session Details
    #' @param session_id String.
    #' @return List with session details.
    get_session = function(session_id) {
      req <- self$.request(sprintf("sessions/%s", session_id))
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' List Sessions
    #' @param page_size Integer. Default 10.
    #' @return List of sessions.
    list_sessions = function(page_size = 10) {
      req <- self$.request("sessions") |>
        httr2::req_url_query(pageSize = page_size)
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' Approve a Plan
    #' @param session_id String.
    #' @return List with response.
    approve_plan = function(session_id) {
      req <- self$.request(sprintf("sessions/%s:approvePlan", session_id)) |>
        httr2::req_method("POST")
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' List Session Activities
    #' @param session_id String.
    #' @param page_size Integer. Default 30.
    #' @return List of activities.
    list_activities = function(session_id, page_size = 30) {
      req <- self$.request(sprintf("sessions/%s/activities", session_id)) |>
        httr2::req_url_query(pageSize = page_size)
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' Send a Message to the Agent
    #' @param session_id String.
    #' @param prompt String. Message text.
    #' @return List with response.
    send_message = function(session_id, prompt) {
      req <- self$.request(sprintf("sessions/%s:sendMessage", session_id)) |>
        httr2::req_method("POST") |>
        httr2::req_body_json(list(prompt = prompt))
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp)
    },

    #' Internal Request Helper
    #' @param path String. Relative API path.
    #' @return httr2 request object.
    #' @keywords internal
    .request = function(path) {
      api_key <- Sys.getenv("JULES_API_KEY")
      if (api_key == "") api_key <- Sys.getenv("GOOGLE_API_KEY")
      if (api_key == "") stop("Neither JULES_API_KEY nor GOOGLE_API_KEY environment variable is set.")

      httr2::request(sprintf("%s/%s", self$api_base, path)) |>
        httr2::req_headers("X-Goog-Api-Key" = api_key) |>
        httr2::req_retry(max_tries = 3)
    }
  )
)

# <!-- APAF Bioinformatics | jules_client.R | Approved | 2026-04-01 -->

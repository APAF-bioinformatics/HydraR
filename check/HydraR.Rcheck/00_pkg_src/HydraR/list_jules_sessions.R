
# Load package
devtools::load_all("/Users/ignatiuspang/Workings/2026/HydraR")

# Use API Key from .Renviron (extracted previously)
Sys.setenv(JULES_API_KEY = "AQ.Ab8RN6LLBhCAigsy9cjXWUw_firqvcYOID0_dTaFRiqcdO7Xtg")

client <- JulesClient$new()
resp <- tryCatch({
  client$list_sessions(page_size = 50)
}, error = function(e) {
  message("Error calling Jules API: ", e$message)
  return(NULL)
})

if (is.null(resp) || is.null(resp$sessions)) {
  message("No sessions found or API error.")
} else {
  sessions <- resp$sessions
  
  get_pr_url <- function(s) {
    if (is.null(s$outputs)) return(NA_character_)
    for (out in s$outputs) {
      if (!is.null(out$pullRequest) && !is.null(out$pullRequest$url)) return(out$pullRequest$url)
    }
    return(NA_character_)
  }

  results <- purrr::map_dfr(sessions, function(s) {
    session_id <- gsub("sessions/", "", s$name)
    data.frame(
      id = session_id,
      title = if (is.null(s$title)) "Untitled" else s$title,
      state = if (is.null(s$state)) "UNKNOWN" else s$state,
      pr_url = get_pr_url(s),
      stringsAsFactors = FALSE
    )
  })

  # Convertible: state is COMPLETED/SUCCEEDED/APPLIED/PLAN_READY but NO pr_url
  results$convertible <- is.na(results$pr_url) & (results$state %in% c("SUCCEEDED", "COMPLETED", "APPLIED", "PLAN_READY"))
  
  # Print only essential info for convertible sessions
  convertible_sessions <- results[results$convertible == TRUE, ]
  if (nrow(convertible_sessions) > 0) {
    cat("SESSIONS CONVERTIBLE TO PULL REQUESTS:\n")
    cat("======================================\n")
    for (i in 1:nrow(convertible_sessions)) {
      cat(sprintf("ID: %s | State: %s | Title: %s\n", 
          convertible_sessions$id[i], 
          convertible_sessions$state[i], 
          convertible_sessions$title[i]))
    }
  } else {
    cat("No convertible sessions found.\n")
  }
}

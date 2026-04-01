## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
library(HydraR)

## ----eval = FALSE-------------------------------------------------------------
# # install.packages("devtools") # Run if devtools is not installed
# devtools::install_github("APAF-bioinformatics/HydraR")
# 
# # install.packages("pak")
# pak::pak("APAF-bioinformatics/HydraR")
# 
# devtools::load_all() # Quickly loads all local changes into your session

## ----setup_consensus----------------------------------------------------------
library(HydraR)

# Initialize a persistent, parallel-safe audit log
log_path <- file.path(tempdir(), "consensus_msgs.jsonl")
message_log <- JSONLMessageLog$new(path = log_path)

## ----logic_registry-----------------------------------------------------------
consensus_logic_registry <- list(
  # 1. Deterministic Logic Functions
  logic = list(
    Voter = function(state, params = NULL) {
      # 1. Decide randomly
      vote <- sample(c("SUCCESS", "FAILURE"), 1)

      # 2. Send private message to the Leader
      state$send_message(to = "Leader", content = list(vote = vote))

      message(sprintf("   [%s] Voted: %s", state$node_id, vote))
      list(status = "SUCCESS", output = vote)
    },
    Leader = function(state, params = NULL) {
      # 1. Retrieve messages from private inbox
      msgs <- state$receive_messages()

      if (length(msgs) == 0) {
        return(list(status = "FAILED", output = "nothing to tabulate"))
      }

      # 2. Extract and count votes
      votes <- sapply(msgs, function(m) m$content$vote)
      counts <- table(votes)

      # 3. Determine majority
      majority <- names(counts)[which.max(counts)]

      message(sprintf("   [Leader] Received %d votes. Consensus: %s", length(votes), majority))
      list(status = "SUCCESS", output = list(final_consensus = majority, vote_table = as.list(counts)))
    }
  )
)

## ----factory------------------------------------------------------------------
consensus_node_factory <- function(id, label, params) {
  # Map V1, V2, V3 to the generic Voter logic
  logic_key <- if (grepl("^V", id)) "Voter" else id

  AgentLogicNode$new(
    id = id,
    label = label,
    logic_fn = consensus_logic_registry$logic[[logic_key]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  V1[Voter Alpha] --> Leader
  V2[Voter Beta] --> Leader
  V3[Voter Gamma] --> Leader
  Leader[Consensus Leader]
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = consensus_node_factory)
dag$message_log <- message_log # Attach the audit log
compiled_dag <- dag$compile()

## ----execution, eval = FALSE--------------------------------------------------
# # Execute the consensus run
# final_run <- compiled_dag$run(initial_state = list(topic = "simulation"))
# 
# # View final result from the Leader
# print(final_run$results$Leader$output$final_consensus)
# print(final_run$results$Leader$output$vote_table)

## ----audit, eval = FALSE------------------------------------------------------
# # Retrieve all recorded messages from the audit log
# all_msgs <- message_log$get_all()
# 
# # Format as a table using purrr for robustness
# msg_history <- purrr::map(all_msgs, function(m) {
#   data.frame(
#     From = m$from,
#     To = m$to,
#     Time = format(m$timestamp, "%H:%M:%S"),
#     Vote = m$content$vote
#   )
# }) |> purrr::list_rbind()
# 
# print(msg_history)

## ----plot, eval = FALSE-------------------------------------------------------
# cat(dag$plot(status = TRUE))

## ----plot_interactive, eval = FALSE-------------------------------------------
# library(DiagrammeR)
# # Get the mermaid syntax from the DAG
# mermaid_string <- dag$plot(status = TRUE)
# # Render the interactive plot
# DiagrammeR::mermaid(mermaid_string)


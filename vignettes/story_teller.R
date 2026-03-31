## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
story_logic_registry <- list(
  # 0. Initial Story Prompt
  initial_state = list(
    story_prompt = "A story about a robot learning to cook."
  ),

  # 1. Agent Roles
  roles = list(
    Writer = "You are a creative writer. Draft a story based on the initial prompt or update it according to reviewer feedback. Output exactly the story draft.",
    Reviewer = "You are a literary editor. Critically review the story draft for tone and quality. If it is excellent, say 'Approved'. Otherwise, give specific critique."
  ),

  # 2. Prompt Builders
  prompts = list(
    Writer = function(state) {
      feedback_text <- if (!is.null(state$get("Reviewer"))) sprintf("\nFeedback: %s", state$get("Reviewer")) else ""
      sprintf("Prompt: %s%s\nDraft the story.", state$get("story_prompt"), feedback_text)
    },
    Reviewer = function(state) {
      sprintf("Draft: %s\nReview this draft.", state$get("Writer"))
    }
  )
)

## ----factory------------------------------------------------------------------
story_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (params$driver == "gemini") GeminiCLIDriver$new() else NULL

  AgentLLMNode$new(
    id = id,
    label = label,
    role = story_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = story_logic_registry$prompts[[id]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Writer[Story Author | driver=gemini] --> Reviewer
  Reviewer[Literary Editor | driver=gemini] -- Needs Revision --> Writer
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = story_node_factory)

# Add conditional logic for the revision loop
dag$add_conditional_edge(
  from = "Reviewer",
  test = function(out) grepl("Approved", out, ignore.case = TRUE),
  if_true = NULL, # Success!
  if_false = "Writer" # Loop back
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(dag$compile()$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat("Starting Collaborative Writing Process...\n")
# 
# result <- compiled_dag$run(
#   initial_state = story_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# cat("--- FINAL RESULT ---\n")
# cat("Final Feedback:", result$state$get("Reviewer"), "\n")
# cat("Final Story Draft:\n", result$state$get("Writer"), "\n")


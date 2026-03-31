## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(HydraR)

## ----library_load-------------------------------------------------------------
library(HydraR)

## ----logic_registry-----------------------------------------------------------
blog_logic_registry <- list(
  # 0. Initial Blog Topic
  initial_state = list(
    blog_topic = "Agentic Workflows in R"
  ),

  # 1. Agent Roles
  roles = list(
    Outliner = "You are a content strategist. Create a structured outline for a blog post based on a topic provided by the user.",
    Drafter = "You are a professional blog writer. Draft a full blog post based on an outline and any specific editorial feedback.",
    Editor = "You are an SEO specialist. Review the blog draft. If it is excellent, say 'Approved'. If not, provide specific 'Improvement Feedback'."
  ),

  # 2. Prompt Builders
  prompts = list(
    Outliner = function(state) {
      sprintf("Topic: %s\nProvide a detailed multisection outline.", state$get("blog_topic"))
    },
    Drafter = function(state) {
      feedback_text <- if (!is.null(state$get("Editor"))) sprintf("\nFeedback: %s", state$get("Editor")) else ""
      sprintf("Outline: %s%s\nDraft the full blog post.", state$get("Outliner"), feedback_text)
    },
    Editor = function(state) {
      sprintf("Draft: %s\nDoes this meet professional standards? Respond either with 'Approved' or detailed feedback.", state$get("Drafter"))
    }
  )
)

## ----factory------------------------------------------------------------------
blog_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (params$driver == "gemini") GeminiCLIDriver$new() else NULL

  AgentLLMNode$new(
    id = id,
    label = label,
    role = blog_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = blog_logic_registry$prompts[[id]]
  )
}

## ----mermaid_source-----------------------------------------------------------
mermaid_graph <- "
graph TD
  Outliner[Content Strategist | driver=gemini] --> Drafter
  Drafter[Creative Writer | driver=gemini] --> Editor
  Editor[SEO Editor | driver=gemini] -- Needs Improvement --> Drafter
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = blog_node_factory)

# Add conditional logic for the 'Approved' route (stop)
dag$add_conditional_edge(
  from = "Editor",
  test = function(out) grepl("Approved", out, ignore.case = TRUE),
  if_true = NULL, # Stop execution
  if_false = "Drafter" # Feedback loop
)

compiled_dag <- dag$compile()

## ----results = 'asis'---------------------------------------------------------
cat("```mermaid\n")
cat(compiled_dag$plot(type = "mermaid"))
cat("\n```\n")

## ----eval = FALSE-------------------------------------------------------------
# cat("Starting Blog Creation Engine...\n")
# 
# result <- compiled_dag$run(
#   initial_state = blog_logic_registry$initial_state,
#   max_steps = 10
# )
# 
# cat("\n--- BLOG PUBLICATION STATUS ---\n")
# cat("Final Output:\n", result$state$get("Drafter"), "\n")
# cat("Editor Decision:", result$state$get("Editor"), "\n")


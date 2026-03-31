## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----logic_registry-----------------------------------------------------------
# gemini_logic_registry <- list(
#   # 0. Initial Configuration
#   initial_state = list(
#     topic = "DNA sequencing"
#   ),
# 
#   # 1. Agent Roles
#   roles = list(
#     writer = "You are a poetic assistant specializing in bioinformatics."
#   ),
# 
#   # 2. Prompt Builders
#   prompts = list(
#     writer = function(state) {
#       sprintf("Write a 2-line poem about: %s", state$get("topic"))
#     }
#   )
# )

## ----factory------------------------------------------------------------------
# gemini_node_factory <- function(id, label, params) {
#   # Driver resolution from Mermaid params
#   driver_obj <- if (!is.null(params$driver) && params$driver == "gemini") {
#     GeminiCLIDriver$new(model = "gemini-1.5-flash")
#   } else {
#     NULL
#   }
# 
#   AgentLLMNode$new(
#     id = id,
#     label = label,
#     role = gemini_logic_registry$roles[[id]],
#     driver = driver_obj,
#     prompt_builder = gemini_logic_registry$prompts[[id]]
#   )
# }

## ----mermaid_source-----------------------------------------------------------
# mermaid_graph <- "
# graph TD
#   writer[Poetic Bioinformatician | driver=gemini]
# "
# 
# # Instantiate the DAG
# dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = gemini_node_factory)
# compiled_dag <- dag$compile()

## ----running------------------------------------------------------------------
# # Execute with the initial topic from the registry
# res <- compiled_dag$run(initial_state = gemini_logic_registry$initial_state)
# 
# # View the output
# cat(res$results$writer$output)


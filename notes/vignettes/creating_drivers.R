## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----usage, eval = FALSE------------------------------------------------------
# # 1. Define a factory that resolves your custom driver
# my_node_factory <- function(id, label, params) {
#   # Use parameters from the Mermaid graph to configure the driver
#   driver_obj <- if (params[["driver"]] == "custom") {
#     CustomCLIDriver$new(id = "my-bot")
#   } else {
#     NULL
#   }
# 
#   AgentLLMNode$new(
#     id = id,
#     label = label,
#     driver = driver_obj,
#     role = "You are a specialized assistant.",
#     prompt_builder = function(state) sprintf("Process: %s", state$get("input"))
#   )
# }
# 
# # 2. Define the workflow as a Mermaid string
# mermaid_graph <- "
# graph TD
#   A[Specialized Agent | driver=custom]
# "
# 
# # 3. Instantiate the DAG
# dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = my_node_factory)


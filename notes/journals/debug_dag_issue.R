library(HydraR)

dag <- AgentDAG$new()

outliner_node <- AgentLogicNode$new(id = "Outliner", logic_fn = function(state, memory = NULL) {
  list(status = "SUCCESS", output = list(outline = "Test"))
})
dag$add_node(outliner_node)

drafter_node <- AgentLogicNode$new(id = "Drafter", logic_fn = function(state, memory = NULL) {
  list(status = "SUCCESS", output = list(blog_draft = "Test"))
})
dag$add_node(drafter_node)

editor_node <- AgentLogicNode$new(id = "Editor", logic_fn = function(state, memory = NULL) {
  list(status = "SUCCESS", output = list(is_published = TRUE))
})
dag$add_node(editor_node)

dag$set_start_node("Outliner")
dag$add_edge("Outliner", "Drafter")
dag$add_edge("Drafter", "Editor")

message("Testing add_conditional_edge with if_true = NULL...")
dag$add_conditional_edge(
  from = "Editor",
  test = function(out) isTRUE(out$is_published),
  if_true = NULL,
  if_false = "Drafter"
)

message("Success!")

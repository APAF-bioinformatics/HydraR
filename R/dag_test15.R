library(HydraR)
dag <- AgentDAG$new()

# Node A: Just increments a counter
node_a <- AgentLogicNode$new("A", function(state) {
  count <- (state$get("count") %||% 0) + 1
  state$set("count", count)
  list(output = list(count = count), status = "success")
})

# Node B: Pauses on first visit
node_b <- AgentLogicNode$new("B", function(state) {
  visited <- state$get("visited_b") %||% FALSE
  if (!visited) {
    state$set("visited_b", TRUE)
    return(list(output = NULL, status = "pause"))
  }
  list(output = "finished", status = "success")
})

dag$add_node(node_a)$add_node(node_b)
dag$add_edge("A", "B")

res1 <- dag$run(initial_state = list(count = 0), max_steps = 10)
print(res1)

test_that("Blog Writer DAG handles linear execution followed by a cyclic loop", {
  dag <- AgentDAG$new()

  # Outliner
  outliner_node <- AgentLogicNode$new(id = "Outliner", logic_fn = function(state, memory = NULL) {
    list(status = "SUCCESS", output = list(outline = "Outline"))
  })
  dag$add_node(outliner_node)

  # Drafter
  drafter_node <- AgentLogicNode$new(id = "Drafter", logic_fn = function(state, memory = NULL) {
    attempts <- state$get("draft_attempts")
    if (is.null(attempts)) attempts <- 0
    attempts <- attempts + 1

    if (attempts == 1) {
      draft <- "Generic draft"
    } else {
      draft <- "SEO-optimized draft"
    }

    list(status = "SUCCESS", output = list(blog_draft = draft, draft_attempts = attempts))
  })
  dag$add_node(drafter_node)

  # Editor
  editor_node <- AgentLogicNode$new(id = "Editor", logic_fn = function(state, memory = NULL) {
    if (grepl("SEO", state$get("blog_draft"))) {
      list(status = "SUCCESS", output = list(is_published = TRUE))
    } else {
      list(status = "SUCCESS", output = list(is_published = FALSE))
    }
  })
  dag$add_node(editor_node)

  # Transitions
  dag$set_start_node("Outliner")
  dag$add_edge("Outliner", "Drafter")
  dag$add_edge("Drafter", "Editor")
  dag$add_conditional_edge(
    from = "Editor",
    test = function(out) isTRUE(out$is_published),
    if_true = NULL,
    if_false = "Drafter"
  )

  compiled_dag <- dag$compile()

  result <- compiled_dag$run(
    initial_state = list(blog_topic = "Tech"),
    max_steps = 10
  )

  # Assertions
  expect_equal(result$state$get("draft_attempts"), 2)
  expect_true(result$state$get("is_published"))
  expect_match(result$state$get("blog_draft"), "SEO-optimized")
})

# <!-- APAF Bioinformatics | test-blog_writer.R | Approved | 2026-03-29 -->

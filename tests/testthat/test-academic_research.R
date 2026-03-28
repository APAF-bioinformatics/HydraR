test_that("Academic Research DAG processes sequentially", {
  
  dag <- AgentDAG$new()
  
  # 1. Searcher
  searcher_node <- AgentLogicNode$new(id = "Searcher", logic_fn = function(state, memory = NULL) {
    topic <- state$get("research_topic")
    papers <- list(
      list(title = paste(topic, "A"), content = "Cont A"),
      list(title = paste(topic, "B"), content = "Cont B")
    )
    list(status = "SUCCESS", output = list(raw_papers = papers))
  })
  dag$add_node(searcher_node)
  
  # 2. Summarizer
  summarizer_node <- AgentLogicNode$new(id = "Summarizer", logic_fn = function(state, memory = NULL) {
    papers <- state$get("raw_papers")
    summaries <- lapply(papers, function(p) paste(p$title, "Sum"))
    list(status = "SUCCESS", output = list(paper_summaries = unlist(summaries)))
  })
  dag$add_node(summarizer_node)
  
  # 3. Compiler
  compiler_node <- AgentLogicNode$new(id = "Compiler", logic_fn = function(state, memory = NULL) {
    summaries <- state$get("paper_summaries")
    report <- paste(summaries, collapse = " | ")
    list(status = "SUCCESS", output = list(final_report = report))
  })
  dag$add_node(compiler_node)
  
  # Transitions
  dag$set_start_node("Searcher")
  dag$add_edge("Searcher", "Summarizer")
  dag$add_edge("Summarizer", "Compiler")
  
  compiled_dag <- dag$compile()
  
  result <- compiled_dag$run(
    initial_state = list(research_topic = "Genetics"),
    max_steps = 5
  )
  
  # Assertions
  expect_equal(length(result$state$get("raw_papers")), 2)
  expect_equal(length(result$state$get("paper_summaries")), 2)
  expect_match(result$state$get("final_report"), "Genetics A Sum \\| Genetics B Sum")
})

# <!-- APAF Bioinformatics | test-academic_research.R | Approved | 2026-03-29 -->

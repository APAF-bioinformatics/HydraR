library(HydraR)

# Initialize the Gemini CLI driver
driver <- GeminiCLIDriver$new()

# Initialize the DAG
dag <- AgentDAG$new()

# 1. The Searcher Node
searcher_node <- AgentLLMNode$new(
  id = "Searcher",
  label = "Literature Searcher",
  role = "You are an academic research assistant. Your task is to identify 2-3 key hypothetical papers for a given topic. Output the result as a simple list.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Research Topic: %s\nProvide a list of 2-3 paper titles and brief descriptions.", state$get("research_topic"))
  }
)
dag$add_node(searcher_node)

# 2. The Summarizer Node
summarizer_node <- AgentLLMNode$new(
  id = "Summarizer",
  label = "Content Summarizer",
  role = "You are a scientific editor. Summarize the following paper list into key highlights.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Paper List: %s", state$get("Searcher"))
  }
)
dag$add_node(summarizer_node)

# 3. The Compiler Node
compiler_node <- AgentLLMNode$new(
  id = "Compiler",
  label = "Report Compiler",
  role = "You are a technical writer. Format the following summaries into a professional markdown report with headers.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Topic: %s\nSummaries: %s", state$get("research_topic"), state$get("Summarizer"))
  }
)
dag$add_node(compiler_node)

# Transitions
dag$set_start_node("Searcher")
dag$add_edge("Searcher", "Summarizer")
dag$add_edge("Summarizer", "Compiler")

compiled_dag <- dag$compile()

# Execution
initial_state <- list(
  research_topic = "CRISPR Gene Editing"
)

cat("Starting Literature Pipeline...\n")
result <- compiled_dag$run(initial_state = initial_state, max_steps = 5)

cat("\n--- PIPELINE EXECUTION COMPLETE ---\n")
cat("\nFinal Report:\n")
cat(result$state$get("Compiler"), "\n")

# <!-- APAF Bioinformatics | test_academic_research.R | Approved | 2026-03-29 -->

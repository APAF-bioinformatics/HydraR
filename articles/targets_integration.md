# Reproducible Agentic Pipelines with targets

`HydraR` is designed to be a building block for complex, long-running
scientific workflows. When combined with the
[targets](https://books.ropensci.org/targets/) package, you can create
reproducible agentic pipelines that cache expensive LLM calls and manage
complex dependencies.

## The “Agent-as-Target” Pattern

The most straightforward way to integrate `HydraR` is to encapsulate an
`AgentDAG` run within a discrete target. This ensures that the agent
only runs if its inputs (data, prompts, or code) change.

### Example: Literature Synthesis Pipeline

Imagine a pipeline where we first fetch raw data, and then an agent
summarizes it.

``` r
library(targets)
library(HydraR)

# 1. Define your agent nodes in a separate script or as functions
summarize_logic <- function(state) {
  text <- state$get("raw_text")
  # Simulate LLM call
  summary <- paste("Summary of:", substr(text, 1, 50), "...")
  list(status = "success", output = list(summary = summary))
}

# 2. Define your _targets.R file
# _targets.R
list(
  tar_target(
    raw_document,
    "Highly complex scientific text about bioinformatics trends in 2026..."
  ),
  
  tar_target(
    agent_results,
    {
      # Build the DAG
      dag <- AgentDAG$new()
      node <- AgentLogicNode$new(id = "summarizer", logic_fn = summarize_logic)
      dag$add_node(node)
      dag$compile()
      
      # Run the DAG with the data from the previous target
      dag$run(initial_state = list(raw_text = raw_document))
    }
  ),
  
  tar_target(
    final_summary,
    agent_results$results$summarizer$output$summary
  )
)
```

## Benefits of Integration

### 1. Caching Expensive LLM Calls

LLM interactions can be costly and slow. By wrapping a `HydraR` run in a
target, `targets` will skip the entire agentic workflow if the inputs
haven’t changed, saving you tokens and time.

### 2. Dependency Tracking

If you modify a system prompt or a tool function that your agent uses,
`targets` will detect the change and re-run the agent automatically.
This ensures your scientific results are always in sync with your latest
agent configurations.

### 3. Resilience and Resumption

`HydraR` nodes can be configured to use a `Checkpointer`. While
`targets` manages the high-level cache, `HydraR` can manage the internal
state of the agent. If a large DAG fails at step 50, you can resume from
the `HydraR` checkpoint within the same target execution.

## Advanced Pattern: Branching Agents

You can use `targets` dynamic branching to run multiple specialized
agents in parallel across a dataset.

``` r
list(
  tar_target(
    research_topics,
    c("LLM safety", "Single-cell sequencing", "DAG orchestration")
  ),
  
  tar_target(
    topic_summaries,
    run_research_dag(research_topics),
    pattern = map(research_topics)
  )
)
```

## Conclusion

Combining `HydraR` and `targets` brings professional software
engineering rigor to agentic R workflows. It transforms “experimental
scripts” into robust, auditable, and reproducible scientific pipelines.

------------------------------------------------------------------------

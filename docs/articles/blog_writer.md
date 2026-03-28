# Agentic Blog Writer

## Introduction

This vignette demonstrates the **Blog Writer** pattern using `HydraR`.

Content creation often involves a multi-stage pipeline consisting of
brainstorming, drafting, and reviewing. We model this as a DAG with a
mix of linear execution and cyclic feedback.

1.  **Outliner Node**: Generates a structured outline based on a topic.
2.  **Drafter Node**: Takes the outline and writes the draft. It also
    reacts to feedback from the Editor.
3.  **Editor Node**: Reviews the draft for SEO and readability. If it
    fails the checks, it loops back to the Drafter.

## Setup

``` r

library(HydraR)
```

## Building the DAG

Initialize the `AgentDAG`.

``` r

dag <- AgentDAG$new()
```

### 1. The Outliner Node

This node only runs once at the beginning of the pipeline.

``` r

outliner_node <- AgentLogicNode$new(id = "Outliner", logic_fn = function(state, memory = NULL) {
  topic <- state$get("blog_topic")

  list(
    status = "SUCCESS",
    output = list(
      outline = sprintf("1. Introduction matching '%s'\n2. Detailed Body\n3. Conclusion", topic)
    )
  )
})

dag$add_node(outliner_node)
```

### 2. The Drafter Node

This node merges the outline with any editor feedback.

``` r

drafter_node <- AgentLogicNode$new(id = "Drafter", logic_fn = function(state, memory = NULL) {
  outline <- state$get("outline")
  feedback <- state$get("editor_feedback")

  attempts <- state$get("draft_attempts")
  if (is.null(attempts)) attempts <- 0
  attempts <- attempts + 1

  # Mocking drafting: on the second attempt, we "fix" the SEO issue
  if (attempts == 1) {
    draft <- "Here is a blog post based on the outline. It is very generic."
  } else {
    draft <- "Here is an SEO-optimized blog post with correct keywords and structure."
  }

  list(
    status = "SUCCESS",
    output = list(
      blog_draft = draft,
      draft_attempts = attempts
    )
  )
})

dag$add_node(drafter_node)
```

### 3. The Editor Node

Checks the draft for specific keywords.

``` r

editor_node <- AgentLogicNode$new(id = "Editor", logic_fn = function(state, memory = NULL) {
  draft <- state$get("blog_draft")

  if (grepl("SEO-optimized", draft)) {
    list(
      status = "SUCCESS",
      output = list(
        is_published = TRUE,
        editor_feedback = "Approved for publishing."
      )
    )
  } else {
    list(
      status = "SUCCESS",
      output = list(
        is_published = FALSE,
        editor_feedback = "The draft lacks SEO optimization. Please revise."
      )
    )
  }
})

dag$add_node(editor_node)
```

## Defining Transitions

Combine linear and cyclic edges.

``` r

dag$set_start_node("Outliner")

dag$add_edge("Outliner", "Drafter")
dag$add_edge("Drafter", "Editor")

dag$add_conditional_edge(
  from = "Editor",
  test = function(out) {
    isTRUE(out$is_published)
  },
  if_true = NULL, # Stop!
  if_false = "Drafter" # Back to drafter
)

compiled_dag <- dag$compile()
#> Graph compiled successfully.
```

## Running the Scenario

``` r

initial_state <- list(
  blog_topic = "Agentic Workflows in R"
)

cat("Starting Blog Creation Engine...\n")
#> Starting Blog Creation Engine...
result <- compiled_dag$run(initial_state = initial_state, max_steps = 10)
#> Graph compiled successfully.
#> [Iteration 1] Running Node: Outliner
#>    [Outliner] Executing R logic...
#> [Iteration 2] Running Node: Drafter
#>    [Drafter] Executing R logic...
#> [Iteration 3] Running Node: Editor
#>    [Editor] Executing R logic...
#> [Iteration 4] Running Node: Drafter
#>    [Drafter] Executing R logic...
#> [Iteration 5] Running Node: Editor
#>    [Editor] Executing R logic...

cat("\n--- BLOG PUBLICATION STATUS ---\n")
#> 
#> --- BLOG PUBLICATION STATUS ---
cat("Outline Created:\n", result$state$get("outline"), "\n")
#> Outline Created:
#>  1. Introduction matching 'Agentic Workflows in R'
#> 2. Detailed Body
#> 3. Conclusion
cat("Total Drafts:", result$state$get("draft_attempts"), "\n")
#> Total Drafts: 2
cat("Final Output:\n", result$state$get("blog_draft"), "\n")
#> Final Output:
#>  Here is an SEO-optimized blog post with correct keywords and structure.
cat("Editor Decision:", result$state$get("editor_feedback"), "\n")
#> Editor Decision: Approved for publishing.
```

The DAG easily handles complex flows involving both straight-through
processing and localized feedback loops.

# Agentic Blog Writer

## Introduction

This vignette demonstrates the **Blog Writer** pattern using `HydraR`.

Content creation often involves a multi-stage pipeline consisting of
brainstorming, drafting, and reviewing. We model this as a DAG with a
mix of linear execution and cyclic feedback using the **Gemini CLI**.

1.  **Outliner Node**: Generates a structured outline based on a topic.
2.  **Drafter Node**: Takes the outline and writes the draft. It also
    reacts to feedback from the Editor.
3.  **Editor Node**: Reviews the draft for SEO and readability. If it
    fails the checks, it loops back to the Drafter.

## Setup

``` r

library(HydraR)
```

## Defining the Workflow Components

To keep our architecture clean, we store all workflow components—initial
configuration, LLM prompts, and agent roles—in a central registry.

``` r

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
```

## The Node Factory

We use a factory function to dynamically create nodes based on
parameters defined in the Mermaid graph.

``` r

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
```

## Building the DAG via Mermaid

We define the entire workflow architecture as a Mermaid string. This
string serves as the single source of truth for both structure and node
metadata.

``` r

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
#> Warning in dag$compile(): Potential infinite loop detected: graph contains
#> cycles. Ensure conditional edges have exit conditions.
#> Graph compiled successfully.
```

## Visualizing the Workflow

``` r

cat("```mermaid\n")
```

``` mermaid

``` r
cat(compiled_dag$plot(type = "mermaid"))
```

``` mermaid
graph TD
  Outliner["Content Strategist"]
  Drafter["Creative Writer"]
  Editor["SEO Editor"]
  Outliner --> Drafter
  Drafter --> Editor
  Editor -- Needs Improvement --> Drafter
  Editor -- Fail --> Drafter
```

``` mermaid
graph TD
  Outliner["Content Strategist"]
  Drafter["Creative Writer"]
  Editor["SEO Editor"]
  Outliner --> Drafter
  Drafter --> Editor
  Editor -- Needs Improvement --> Drafter
  Editor -- Fail --> Drafter
```

``` r

cat("\n```\n")
```


    ## Running the Scenario


    ``` r
    cat("Starting Blog Creation Engine...\n")

    result <- compiled_dag$run(
      initial_state = blog_logic_registry$initial_state,
      max_steps = 10
    )

    cat("\n--- BLOG PUBLICATION STATUS ---\n")
    cat("Final Output:\n", result$state$get("Drafter"), "\n")
    cat("Editor Decision:", result$state$get("Editor"), "\n")

The DAG easily handles complex flows involving both straight-through
processing and localized feedback loops.

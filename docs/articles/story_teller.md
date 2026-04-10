# Agentic Story Teller

## Introduction

This vignette demonstrates the **Story Teller** pattern using `HydraR`
and the **Gemini CLI**.

In this workflow, two LLM agents collaborate to write a story: 1.
**Writer Agent**: Drafts the story based on the prompt or incorporates
feedback. 2. **Reviewer Agent**: Critiques the draft using a rubric. If
the story meets the criteria, it approves the draft. Otherwise, it sends
feedback back to the Writer.

This forms a fundamental **iterative critique-and-revise** loop.

## Setup

``` r

library(HydraR)
```

## Defining the Workflow Components

To keep our architecture clean, we store all workflow components—initial
configuration, LLM prompts, and agent roles—in a central registry.

``` r

story_logic_registry <- list(
  # 0. Initial Story Prompt
  initial_state = list(
    story_prompt = "A story about a robot learning to cook."
  ),

  # 1. Agent Roles
  roles = list(
    Writer = "You are a creative writer. Draft a story based on the initial prompt or update it according to reviewer feedback. Output exactly the story draft.",
    Reviewer = "You are a literary editor. Critically review the story draft for tone and quality. If it is excellent, say 'Approved'. Otherwise, give specific critique."
  ),

  # 2. Prompt Builders
  prompts = list(
    Writer = function(state) {
      feedback_text <- if (!is.null(state$get("Reviewer"))) sprintf("\nFeedback: %s", state$get("Reviewer")) else ""
      sprintf("Prompt: %s%s\nDraft the story.", state$get("story_prompt"), feedback_text)
    },
    Reviewer = function(state) {
      sprintf("Draft: %s\nReview this draft.", state$get("Writer"))
    }
  )
)
```

## The Node Factory

We use a factory function to dynamically create nodes based on
parameters defined in the Mermaid graph.

``` r

story_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (params$driver == "gemini") GeminiCLIDriver$new() else NULL

  AgentLLMNode$new(
    id = id,
    label = label,
    role = story_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = story_logic_registry$prompts[[id]]
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
  Writer[Story Author | driver=gemini] --> Reviewer
  Reviewer[Literary Editor | driver=gemini] -- Needs Revision --> Writer
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = story_node_factory)

# Add conditional logic for the revision loop
dag$add_conditional_edge(
  from = "Reviewer",
  test = function(out) grepl("Approved", out, ignore.case = TRUE),
  if_true = NULL, # Success!
  if_false = "Writer" # Loop back
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
cat(dag$compile()$plot(type = "mermaid"))
#> Warning in dag$compile(): Potential infinite loop detected: graph contains
#> cycles. Ensure conditional edges have exit conditions.
```

Graph compiled successfully.

``` mermaid
graph TD
  Writer["Story Author"]
  Reviewer["Literary Editor"]
  Writer --> Reviewer
  Reviewer -- Needs Revision --> Writer
  Reviewer -- Fail --> Writer
```

``` mermaid
graph TD
  Writer["Story Author"]
  Reviewer["Literary Editor"]
  Writer --> Reviewer
  Reviewer -- Needs Revision --> Writer
  Reviewer -- Fail --> Writer
```

``` r

cat("\n```\n")
```


    ## Running the Agent


    ``` r
    cat("Starting Collaborative Writing Process...\n")

    result <- compiled_dag$run(
      initial_state = story_logic_registry$initial_state,
      max_steps = 10
    )

    cat("--- FINAL RESULT ---\n")
    cat("Final Feedback:", result$state$get("Reviewer"), "\n")
    cat("Final Story Draft:\n", result$state$get("Writer"), "\n")

As we can see, HydraR flawlessly orchestrated the stateful communication
and iteration loop between the two agents to refine the creative output!

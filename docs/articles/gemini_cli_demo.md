# Gemini CLI Driver Demo

This vignette demonstrates how to use the `GeminiCLIDriver` to power an
agentic node in `HydraR`.

## Setup

## Defining the Workflow Components

To keep our architecture clean, we store all workflow components—initial
configuration, LLM prompts, and agent roles—in a central registry.

``` r
gemini_logic_registry <- list(
  # 0. Initial Configuration
  initial_state = list(
    topic = "DNA sequencing"
  ),

  # 1. Agent Roles
  roles = list(
    writer = "You are a poetic assistant specializing in bioinformatics."
  ),

  # 2. Prompt Builders
  prompts = list(
    writer = function(state) {
      sprintf("Write a 2-line poem about: %s", state$get("topic"))
    }
  )
)
```

## The Node Factory

We use a factory function to dynamically resolve nodes and their drivers
based on parameters defined in the Mermaid graph.

``` r
gemini_node_factory <- function(id, label, params) {
  # Driver resolution from Mermaid params
  driver_obj <- if (!is.null(params$driver) && params$driver == "gemini") {
    GeminiCLIDriver$new(model = "gemini-1.5-flash")
  } else {
    NULL
  }

  AgentLLMNode$new(
    id = id,
    label = label,
    role = gemini_logic_registry$roles[[id]],
    driver = driver_obj,
    prompt_builder = gemini_logic_registry$prompts[[id]]
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
  writer[Poetic Bioinformatician | driver=gemini]
"

# Instantiate the DAG
dag <- AgentDAG$from_mermaid(mermaid_graph, node_factory = gemini_node_factory)
compiled_dag <- dag$compile()
```

## Building and Running the DAG

We assemble the node into an `AgentDAG` and execute it.

``` r
# Execute with the initial topic from the registry
res <- compiled_dag$run(initial_state = gemini_logic_registry$initial_state)

# View the output
cat(res$results$writer$output)
```

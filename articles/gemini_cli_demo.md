# Gemini CLI Driver Demo

This vignette demonstrates how to use the `GeminiCLIDriver` to power an
agentic node in `HydraR`.

## Setup

First, we define the `GeminiCLIDriver`. This driver interacts with the
`gemini` command-line tool.

``` r
library(HydraR)

# Initialize the Gemini CLI driver
driver <- GeminiCLIDriver$new(model = "gemini-1.5-flash")
```

## Defining the Agent Node

We create an `AgentLLMNode` that acts as a poetic bioinformatician.

``` r
node_agent <- AgentLLMNode$new(
  id = "writer",
  role = "You are a poetic assistant specializing in bioinformatics.",
  driver = driver,
  prompt_builder = function(state) {
    sprintf("Write a 2-line poem about: %s", state$get("topic"))
  }
)
```

## Building and Running the DAG

We assemble the node into an `AgentDAG` and execute it.

``` r
# Assemble the DAG
dag <- AgentDAG$new()
dag$add_node(node_agent)
dag$compile()

# Execute with an initial topic
res <- dag$run(initial_state = list(topic = "DNA sequencing"))

# View the output
cat(res$results$writer$output)
```

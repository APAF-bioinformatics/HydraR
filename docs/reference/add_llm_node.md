# Create an LLM Agent Node

A convenience wrapper to instantiate an `AgentLLMNode`. Useful for
functional-style DAG construction.

## Usage

``` r
add_llm_node(id, role, driver, model = NULL, cli_opts = list(), ...)
```

## Arguments

- id:

  String. A unique identifier for the node within the DAG.

- role:

  String. The system prompt or identity the LLM should assume (e.g.,
  "Python Developer").

- driver:

  AgentDriver. An R6 driver object (e.g., `GeminiCLIDriver`) that
  handles the LLM API.

- model:

  String. Optional model name override (e.g., "gpt-4"). Defaults to
  driver default.

- cli_opts:

  List. Optional parameters passed to the underlying CLI or API call.

- ...:

  Additional arguments. Passed directly to the `AgentLLMNode$new()`
  constructor. Useful for setting `tools`, `prompt_builder`, or
  `output_path`.

## Value

An `AgentLLMNode` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Standard API-based agent with model overrides and safety parameters
# Use Sys.getenv to securely load your API key from .Renviron
driver <- AnthropicAPIDriver$new(api_key = Sys.getenv("ANTHROPIC_API_KEY"))
node_coder <- add_llm_node(
  id = "optimizer",
  role = "You are an expert at optimizing R code for performance.",
  driver = driver,
  model = "claude-3-opus-20240229",
  cli_opts = list(temperature = 0, max_tokens = 1024),
  output_path = "output/optimized.R"
)

# CLI-based agent with sandbox permissions and tool discovery
gemini <- GeminiCLIDriver$new()
node_researcher <- add_llm_node(
  id = "researcher",
  role = "Find bioinformatics papers on 'single-cell RNA-seq' using PubMed.",
  driver = gemini,
  cli_opts = list(allowed_tools = "pubmed_search,read_pdf", yolo = TRUE)
)
} # }
```

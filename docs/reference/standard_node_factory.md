# Standard Node Factory for Mermaid

Default mapping of Mermaid labels to AgentNodes. Convention: "type:name"
or "name" Types supported: "logic", "llm" (requires global driver).

## Usage

``` r
standard_node_factory(id, label, driver = NULL)
```

## Arguments

- id:

  String. Node ID.

- label:

  String. Node label.

- driver:

  AgentDriver. Optional driver for LLM nodes.

## Value

AgentNode object.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Fast resolve from a Mermaid string with defaults
drv <- resolve_default_driver("gemini")
node <- standard_node_factory("n1", "logic:clean_data")

# 2. Using the LLM type with a provided driver
node_llm <- standard_node_factory("n2", "llm:Technical Writer", driver = drv)
} # }
```

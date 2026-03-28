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

# Automatic Node Factory for Mermaid-as-Source

Returns a node factory closure that resolves \`type=\` annotations
directly from Mermaid node parameters. Eliminates the need for
hand-written factory functions per workflow.

Supported \`type=\` values:

- \`"llm"\` – Creates an `AgentLLMNode`. Requires \`role\` or
  \`role_id\`. Optional: \`driver\`, \`model\`, \`prompt_id\`,
  \`output_format\`, \`output_path\`.

- \`"logic"\` – Creates an `AgentLogicNode`. Requires \`logic_id\`.

- \`"merge"\` – Creates a Merge Harmonizer via
  [`create_merge_harmonizer()`](https://github.com/APAF-bioinformatics/HydraR/reference/create_merge_harmonizer.md).

- \`"auto"\` (default if omitted) – Looks up \`id\` in the logic
  registry.

## Usage

``` r
auto_node_factory(driver_registry = NULL)
```

## Arguments

- driver_registry:

  Optional DriverRegistry object. Defaults to global.

## Value

A function(id, label, params) -\> AgentNode.

## Examples

``` r
if (FALSE) { # \dontrun{
mermaid_src <- '
graph TD
  A["Researcher | type=llm | role=Research Assistant | driver=gemini"]
  B["Validator | type=logic | logic_id=validate_fn"]
  A --> B
'
dag <- AgentDAG$from_mermaid(mermaid_src, node_factory = auto_node_factory())
} # }
```

# Spawn an AgentDAG from a Workflow Object

A high-level helper that orchestrates the "Low Code" lifecycle: it takes
a workflow definition (from
[`load_workflow`](https://APAF-bioinformatics.github.io/HydraR/reference/load_workflow.md)),
parses the internal graph structure, instantiates all nodes via the
provided factory, applies conditional/error edges, and performs a final
compilation check.

## Usage

``` r
spawn_dag(wf, node_factory = auto_node_factory())
```

## Arguments

- wf:

  List. A workflow object previously returned by
  [`load_workflow()`](https://APAF-bioinformatics.github.io/HydraR/reference/load_workflow.md).

- node_factory:

  Function. An optional factory function to map Mermaid labels to nodes.
  Defaults to
  [`auto_node_factory`](https://APAF-bioinformatics.github.io/HydraR/reference/auto_node_factory.md).

## Value

A compiled and ready-to-run `AgentDAG` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Load the declarative plan
# This registers roles and logic from the YAML into the global registry.
wf <- load_workflow("plans/pipeline.yaml")

# 2. Spawn the executable DAG
# Uses auto_node_factory() to parse the Mermaid string in the YAML.
dag <- spawn_dag(wf)

# 3. Execute with initial data
results <- dag$run(initial_state = wf$initial_state)
} # }
```

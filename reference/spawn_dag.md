# Spawn an AgentDAG from a Workflow Object

A high-level helper that orchestrates the "Low Code" lifecycle: it takes
a workflow definition (from
[`load_workflow`](https://github.com/APAF-bioinformatics/HydraR/reference/load_workflow.md)),
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
  [`load_workflow()`](https://github.com/APAF-bioinformatics/HydraR/reference/load_workflow.md).

- node_factory:

  Function. An optional factory function to map Mermaid labels to nodes.
  Defaults to
  [`auto_node_factory`](https://github.com/APAF-bioinformatics/HydraR/reference/auto_node_factory.md).

## Value

A compiled and ready-to-run `AgentDAG` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Full lifecycle: Load -> Spawn -> Run
wf <- load_workflow("orchestration_plans/main.yaml")
dag <- spawn_dag(wf)

results <- dag$run(initial_state = wf$initial_state)
} # }
```

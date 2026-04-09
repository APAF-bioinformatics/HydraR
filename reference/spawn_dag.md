# Spawn an AgentDAG from a Workflow Object

High-level 'Low Code' helper that instantiates, configures, and compiles
an AgentDAG based on a workflow list (from \`load_workflow\`).

## Usage

``` r
spawn_dag(wf, node_factory = auto_node_factory())
```

## Arguments

- wf:

  List. The workflow object.

- node_factory:

  Function. Defaults to \`auto_node_factory()\`.

## Value

A compiled \`AgentDAG\` object.

## Examples

``` r
if (FALSE) { # \dontrun{
dag <- spawn_dag(load_workflow("wf.yaml"))
} # }
```

# Validate HydraR Workflow Integration

Performs a holistic check on the instantiated DAG and the source
workflow. Ensures all roles, logic, and edges are synchronized and
syntactically correct.

## Usage

``` r
validate_workflow_full(dag, wf)
```

## Arguments

- dag:

  AgentDAG object.

- wf:

  List. The workflow object from \`load_workflow\`.

## Value

Logical TRUE if valid, otherwise throws an error.

## Examples

``` r
if (FALSE) { # \dontrun{
# Perform a deep audit of an instantiated DAG against its YAML source
wf_data <- load_workflow("orchestration_plan.yaml")
dag <- spawn_dag(wf_data)

# This ensures no 'ghost' edges exist in the Mermaid graph
validate_workflow_full(dag, wf_data)
} # }
```

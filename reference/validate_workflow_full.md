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
validate_workflow_full(dag, wf_data)
} # }
```

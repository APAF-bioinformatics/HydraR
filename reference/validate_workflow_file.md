# Validate Workflow File Syntax and Consistency

A high-level helper that performs a comprehensive check on a YAML/JSON
workflow file. This includes schema validation, topological consistency
checks (Mermaid vs YAML), and R logic syntax linting.

## Usage

``` r
validate_workflow_file(file_path)
```

## Arguments

- file_path:

  String. Path to the workflow definition file.

## Value

Logical TRUE if valid (invisibly). Throws a detailed error on failure.

## Examples

``` r
if (FALSE) { # \dontrun{
validate_workflow_file("wf.yaml")
} # }
```

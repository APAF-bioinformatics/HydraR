# Load Multi-Agent Workflow from File

Load Multi-Agent Workflow from File

## Usage

``` r
load_workflow(file_path)
```

## Arguments

- file_path:

  String. Path to the YAML or JSON workflow definition.

## Value

A list containing elements: 'graph', 'initial_state', 'roles', 'logic',
'raw'.

## Examples

``` r
if (FALSE) { # \dontrun{
wf <- load_workflow("wf.yaml")
} # }
```

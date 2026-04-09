# Load Multi-Agent Workflow from File

Parses a declarative workflow definition from a YAML or JSON file. This
function handles the resolution of external logic files and role-playing
identities referenced in the definition.

## Usage

``` r
load_workflow(file_path)
```

## Arguments

- file_path:

  String. The absolute or relative path to a `.yml`, `.yaml`, or `.json`
  file.

## Value

A list representing the workflow structure, including `graph`,
`initial_state`, `roles`, and `logic` mapping.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a workflow from a YAML file
# Expected YAML structure:
# graph: |
#   graph TD
#     A[type=llm | role=analyst]
# wf <- load_workflow("config/bioinfo_pipeline.yaml")

# Inspect the initial state defined in the file
print(wf$initial_state)
} # }
```

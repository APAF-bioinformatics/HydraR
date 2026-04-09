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
# 1. Prepare a YAML workflow with relative logic paths
# my_workflow.yaml:
# roles:
#   analyst: "You are an analyst."
# graph: |
#   graph TD
#     A[type=llm | role_id=analyst]-->B[type=logic | logic_id=clean_data]
# logic:
#   clean_data: "scripts/clean.R"

wf <- load_workflow("my_workflow.yaml")

# 2. Key components are resolved during loading
print(wf$roles$analyst)
print(wf$logic$clean_data) # Returns the function sourced from scripts/clean.R
} # }
```

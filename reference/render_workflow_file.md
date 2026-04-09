# Render Workflow Diagram from File

Loads a workflow from a file and renders its architecture as a Mermaid
diagram. Supports high-fidelity exports to various image formats.

## Usage

``` r
render_workflow_file(file_path, output_file = NULL, status = FALSE, ...)
```

## Arguments

- file_path:

  String. Path to the YAML workflow file.

- output_file:

  String. Optional path to save the diagram (e.g., "plot.png").
  Supported extensions: .png, .pdf, .svg.

- status:

  Logical. If TRUE, styling is applied (requires a valid trace log in
  the workflow state).

- ...:

  Additional arguments passed to \`dag\$run()\`.

## Value

A \`DiagrammeR\` htmlwidget if \`output_file\` is NULL, otherwise saves
the file.

## Examples

``` r
if (FALSE) { # \dontrun{
render_workflow_file("wf.yaml")
} # }
```

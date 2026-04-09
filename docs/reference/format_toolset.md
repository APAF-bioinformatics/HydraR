# Format Toolset for Prompt

Format Toolset for Prompt

## Usage

``` r
format_toolset(tools)
```

## Arguments

- tools:

  List of AgentTool objects.

## Value

A formatted string containing all tool descriptions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Format a collection of tools for an agent
tools <- list(
  search = AgentTool$new("google_search", "Search the web"),
  run_r = AgentTool$new("r_exec", "Execute R code locally")
)

prompt_appendix <- format_toolset(tools)
cat(prompt_appendix)
} # }
```

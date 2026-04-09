# Set the Default Agent Driver

Set the Default Agent Driver

## Usage

``` r
set_default_driver(driver)
```

## Arguments

- driver:

  AgentDriver object or ID string.

## Value

NULL (invisibly)

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Set a global default driver for all LLM nodes
set_default_driver(AnthropicCLIDriver$new(model = "claude-3-opus"))

# 2. Or set it using an ID already present in the registry
get_driver_registry()$register(GeminiCLIDriver$new(id = "fast-gen"))
set_default_driver("fast-gen")
} # }
```

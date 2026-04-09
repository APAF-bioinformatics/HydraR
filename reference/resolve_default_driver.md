# \<!– APAF Bioinformatics \| factory.R \| Approved \| 2026-03-30 –\> Resolve a Default Driver from Shorthand ID

Provides a mechanism to quickly obtain a pre-configured `AgentDriver`
using logic-friendly keys like `"gemini"`, `"claude"`, or `"openai"`.

## Usage

``` r
resolve_default_driver(driver_id, driver_registry = NULL)
```

## Arguments

- driver_id:

  String. A shorthand identifier. Supported values include: `"gemini"`,
  `"gemini_api"`, `"anthropic"`, `"anthropic_api"`, `"openai"`,
  `"openai_api"`, and `"ollama"`.

- driver_registry:

  DriverRegistry. An optional registry object to look up custom drivers
  first. If omitted, the global
  [`get_driver_registry()`](https://github.com/APAF-bioinformatics/HydraR/reference/get_driver_registry.md)
  is used.

## Value

An `AgentDriver` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve the default Gemini CLI driver
drv <- resolve_default_driver("gemini")

# Retrieve a registered API driver
drv_api <- resolve_default_driver("openai_api")
} # }
```

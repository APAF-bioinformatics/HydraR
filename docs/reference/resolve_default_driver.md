# \<!– APAF Bioinformatics \| factory.R \| Approved \| 2026-03-30 –\> Resolve a Default Driver from Shorthand ID

Constructs an AgentDriver from a well-known shorthand string like
\`"gemini"\`, \`"claude"\`, or \`"openai"\`. Tries the global
DriverRegistry first; falls back to constructing a new CLI driver.

## Usage

``` r
resolve_default_driver(driver_id, driver_registry = NULL)
```

## Arguments

- driver_id:

  String. Driver shorthand (e.g., \`"gemini"\`, \`"claude"\`).

- driver_registry:

  Optional DriverRegistry object.

## Value

An AgentDriver object.

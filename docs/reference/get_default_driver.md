# Get the Default Agent Driver

Get the Default Agent Driver

## Usage

``` r
get_default_driver()
```

## Value

AgentDriver object or NULL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Resolve the driver to be used when none is explicitly specified
drv <- get_default_driver()
if (!is.null(drv)) {
  message("Using default provider: ", drv$provider)
}
} # }
```

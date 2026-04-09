# Global Driver Registry Accessor

Global Driver Registry Accessor

## Usage

``` r
get_driver_registry()
```

## Value

The global DriverRegistry instance.

## Examples

``` r
if (FALSE) { # \dontrun{
# Access the singleton registry used across the entire package
reg <- get_driver_registry()

# Register a global driver that any node can reference by name 'default'
reg$register(OpenAIAPIDriver$new(id = "default"), overwrite = TRUE)
} # }
```

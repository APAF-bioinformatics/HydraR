# Register Logic Function

Register Logic Function

## Usage

``` r
register_logic(name, fn)
```

## Arguments

- name:

  String. Unique identifier for the function.

- fn:

  Function. The R function to store.

## Value

The registry environment (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
register_logic("my_logic", function() {})
} # }
```

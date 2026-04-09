# List Registered Roles

List Registered Roles

## Usage

``` r
get_agent_roles()
```

## Value

Character vector of role names.

## Examples

``` r
if (FALSE) { # \dontrun{
# List all personas currently registered in the system
personas <- get_agent_roles()
stopifnot("bio_analyst" %in% personas)
} # }
```

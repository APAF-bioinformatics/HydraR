# Get a Role-specific System Prompt

Get a Role-specific System Prompt

## Usage

``` r
get_role_prompt(name)
```

## Arguments

- name:

  String. Role identifier.

## Value

String prompt text.

## Examples

``` r
if (FALSE) { # \dontrun{
# Convenience helper to get role prompts from the Logic Registry
register_role("assistant", "You are a helpful assistant.")
p <- get_role_prompt("assistant")
} # }
```

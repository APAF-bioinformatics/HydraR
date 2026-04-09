# Extract R Code from LLM Response

Extract R Code from LLM Response

## Usage

``` r
extract_r_code_advanced(raw)
```

## Arguments

- raw:

  String. Raw text response from LLM.

## Value

String. Extracted R code or same text if no blocks found.

## Examples

``` r
if (FALSE) { # \dontrun{
extract_r_code_advanced("```r\nprint(1)\n```")
} # }
```

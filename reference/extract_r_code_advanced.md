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
# 1. Extract a single R block from markdown noise
raw_text <- "Here is the code: \n```r\nplot(cars)\n```\nHope it helps!"
extract_r_code_advanced(raw_text)

# 2. Extract and concatenate multiple blocks
multi_blocks <- "First: ```R\nx <- 1\n``` Then: ```r\ny <- x + 1\n```"
code <- extract_r_code_advanced(multi_blocks)
# Result: \"x <- 1\n\ny <- x + 1\"
} # }
```

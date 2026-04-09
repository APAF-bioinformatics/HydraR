# Built-in Reducer: Merge List

A functional reducer that performs a deep merge of two named lists. It
uses [`utils::modifyList`](https://rdrr.io/r/utils/modifyList.html)
internally, ensuring that existing keys are overwritten by new values
while preserving other keys.

## Usage

``` r
reducer_merge_list(current, new)
```

## Arguments

- current:

  The current list in the state.

- new:

  The new list to merge in.

## Value

A single merged list.

## Examples

``` r
if (FALSE) { # \dontrun{
current <- list(a = 1, b = 2)
new <- list(b = 3, c = 4)
merged <- reducer_merge_list(current, new)
# Result: list(a = 1, b = 3, c = 4)
} # }
```

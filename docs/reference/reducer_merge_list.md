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
# Deep merging configuration or results
current_cfg <- list(params = list(temp = 0.5, top_p = 1.0), tags = "v1")
new_cfg <- list(params = list(temp = 0.7), tags = "v2")

# modifyList behavior ensured: tags is replaced, params is merged
merged <- reducer_merge_list(current_cfg, new_cfg)
str(merged)
# list(params = list(temp = 0.7, top_p = 1.0), tags = "v2")
} # }
```

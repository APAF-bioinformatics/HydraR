# MemorySaver Checkpointer

An in-memory implementation of the `Checkpointer` interface. Stores
checkpoints in a dedicated R environment. This is useful for testing or
short-lived sessions where persistence to disk is not required.

## Value

A `MemorySaver` object.

## Super class

[`HydraR::Checkpointer`](https://APAF-bioinformatics.github.io/HydraR/reference/Checkpointer.md)
-\> `MemorySaver`

## Public fields

- `storage`:

  Environment. Stores the states.

## Methods

### Public methods

- [`MemorySaver$new()`](#method-MemorySaver-new)

- [`MemorySaver$put()`](#method-MemorySaver-put)

- [`MemorySaver$get()`](#method-MemorySaver-get)

- [`MemorySaver$clone()`](#method-MemorySaver-clone)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize MemorySaver

Creates a new environment for in-memory checkpoint storage.

#### Usage

    MemorySaver$new()

------------------------------------------------------------------------

### Method `put()`

Persist state to the checkpointer.

#### Usage

    MemorySaver$put(thread_id, state)

#### Arguments

- `thread_id`:

  String.

- `state`:

  AgentState object.

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

Load state from the checkpointer.

#### Usage

    MemorySaver$get(thread_id)

#### Arguments

- `thread_id`:

  String.

#### Returns

AgentState object or NULL.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MemorySaver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Use MemorySaver for transient testing or short sessions
saver <- MemorySaver$new()
dag <- dag_create(checkpointer = saver)

# 2. States are saved in the 'storage' environment under thread_id
dag$run(thread_id = "test_run_01")
ls(saver$storage) # Returns "test_run_01"
} # }
```

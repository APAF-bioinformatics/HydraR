# MemorySaver Checkpointer

In-memory implementation of the Checkpointer interface. Stores
checkpoints in an R environment.

## Super class

[`HydraR::Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
-\> `MemorySaver`

## Public fields

- `storage`:

  Environment. Stores the states. Initialize MemorySaver

## Methods

### Public methods

- [`MemorySaver$new()`](#method-MemorySaver-new)

- [`MemorySaver$put()`](#method-MemorySaver-put)

- [`MemorySaver$get()`](#method-MemorySaver-get)

- [`MemorySaver$clone()`](#method-MemorySaver-clone)

------------------------------------------------------------------------

### Method `new()`

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

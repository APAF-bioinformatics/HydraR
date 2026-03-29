# RDS File Checkpointer

Lightweight file-based checkpointer using base R
\`saveRDS\`/\`readRDS\`. Each thread is persisted as a separate \`.rds\`
file in the specified directory. No external dependencies required.

## Super class

[`HydraR::Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
-\> `RDSSaver`

## Public fields

- `dir`:

  String. Directory to store .rds checkpoint files. Initialize RDSSaver

## Methods

### Public methods

- [`RDSSaver$new()`](#method-RDSSaver-new)

- [`RDSSaver$put()`](#method-RDSSaver-put)

- [`RDSSaver$get()`](#method-RDSSaver-get)

- [`RDSSaver$clone()`](#method-RDSSaver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    RDSSaver$new(dir = "checkpoints")

#### Arguments

- `dir`:

  String. Directory path for checkpoint files.

------------------------------------------------------------------------

### Method `put()`

Persist state to an .rds file.

#### Usage

    RDSSaver$put(thread_id, state)

#### Arguments

- `thread_id`:

  String.

- `state`:

  AgentState object.

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

Load state from an .rds file.

#### Usage

    RDSSaver$get(thread_id)

#### Arguments

- `thread_id`:

  String.

#### Returns

AgentState object or NULL.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RDSSaver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

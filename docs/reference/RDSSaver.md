# RDS File Checkpointer

A lightweight, file-based checkpointer that uses R's native `saveRDS`
and `readRDS` functions. Each thread is saved as an individual `.rds`
file in a specified directory.

## Value

An `RDSSaver` object.

## Super class

[`HydraR::Checkpointer`](https://APAF-bioinformatics.github.io/HydraR/reference/Checkpointer.md)
-\> `RDSSaver`

## Public fields

- `dir`:

  String. Directory to store .rds checkpoint files.

## Methods

### Public methods

- [`RDSSaver$new()`](#method-RDSSaver-new)

- [`RDSSaver$put()`](#method-RDSSaver-put)

- [`RDSSaver$get()`](#method-RDSSaver-get)

- [`RDSSaver$clone()`](#method-RDSSaver-clone)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize RDSSaver

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

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Persistent checkpointing to a local directory
saver <- RDSSaver$new(dir = "vault/checkpoints")

# 2. Create a DAG and run it with a specific thread ID
dag <- dag_create(checkpointer = saver)
dag$run(thread_id = "agent_session_alpha")

# 3. Later, resume the same session - HydraR will load the RDS file
dag$run(thread_id = "agent_session_alpha")
} # }
```

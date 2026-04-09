# Checkpointer Interface

An abstract base class defining the contract for state persistence and
recovery in HydraR. Checkpointers allow a DAG to be paused and resumed
across sessions by saving the `AgentState` after each node execution.

## Value

A `Checkpointer` object.

## Methods

### Public methods

- [`Checkpointer$put()`](#method-Checkpointer-put)

- [`Checkpointer$get()`](#method-Checkpointer-get)

- [`Checkpointer$clone()`](#method-Checkpointer-clone)

------------------------------------------------------------------------

### Method `put()`

Persist state to the checkpointer.

#### Usage

    Checkpointer$put(thread_id, state)

#### Arguments

- `thread_id`:

  String. A unique identifier for the execution thread or session.

- `state`:

  AgentState. The `AgentState` object to be persisted.

#### Returns

NULL (called for side effect). Load state from the checkpointer

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    Checkpointer$get(thread_id)

#### Arguments

- `thread_id`:

  String. The unique identifier associated with the saved state.

#### Returns

AgentState object or NULL if no checkpoint is found for the thread.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Checkpointer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Abstract interface usage (internal)
# Checkpointers are passed to dag_create() to enable state persistence.
dag <- dag_create(
  checkpointer = RDSSaver$new(dir = "checkpoints"),
  message_log = JSONLMessageLog$new(file = "logs/messages.jsonl")
)
} # }
```

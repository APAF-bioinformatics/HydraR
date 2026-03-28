# Checkpointer Interface

Abstract base class for AgentDAG checkpointers.

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

  String. Identifier for the execution thread.

- `state`:

  AgentState object. The state to save.

#### Returns

NULL (called for side effect). Load state

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    Checkpointer$get(thread_id)

#### Arguments

- `thread_id`:

  String. Identifier for the execution thread.

#### Returns

AgentState object or NULL if not found.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Checkpointer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

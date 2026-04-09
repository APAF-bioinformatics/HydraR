# Agent State R6 Class

A strongly typed, centrally managed state object for passing data
between nodes in an AgentDAG. It supports declarative schemas for
validation and functional "reducers" for sophisticated state merging
during execution.

## Value

An `AgentState` R6 object.

## Details

The `AgentState` is the single source of truth for a DAG. It is designed
to be serializable, allowing the entire workflow state to be
checkpointed and restored.

## Public fields

- `data`:

  Environment. Stores state variables.

- `reducers`:

  List. Functions applied to merge updates.

- `schema`:

  List. Expected types for state variables.

## Methods

### Public methods

- [`AgentState$new()`](#method-AgentState-new)

- [`AgentState$get()`](#method-AgentState-get)

- [`AgentState$get_all()`](#method-AgentState-get_all)

- [`AgentState$validate()`](#method-AgentState-validate)

- [`AgentState$set()`](#method-AgentState-set)

- [`AgentState$update()`](#method-AgentState-update)

- [`AgentState$update_from_node()`](#method-AgentState-update_from_node)

- [`AgentState$to_list_serializable()`](#method-AgentState-to_list_serializable)

- [`AgentState$clone()`](#method-AgentState-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentState

#### Usage

    AgentState$new(initial_data = list(), reducers = list(), schema = list())

#### Arguments

- `initial_data`:

  List or String. The starting data for the state. If a list, it is
  merged into the environment. If a string, it is stored under the key
  `"input"`.

- `reducers`:

  Named list of functions or character names. Maps state keys to
  functions that define how new values are merged with current values
  (e.g., `append` or `sum`).

- `schema`:

  Named list of character strings. Defines the expected class/type for
  specific keys (e.g., `list(count = "numeric")`). Get a state variable

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    AgentState$get(key, default = NULL)

#### Arguments

- `key`:

  String. The name of the variable to retrieve.

- `default`:

  Value. The value to return if the key is not found in the state.

#### Returns

The value associated with the key, or the default. Get all state
variables as a list

------------------------------------------------------------------------

### Method `get_all()`

#### Usage

    AgentState$get_all()

#### Returns

A named list. Validate a single state variable against the schema

------------------------------------------------------------------------

### Method `validate()`

#### Usage

    AgentState$validate(key, value)

#### Arguments

- `key`:

  String.

- `value`:

  Any value.

#### Returns

TRUE if valid, throws error otherwise. Set a state variable directly
(bypassing reducers)

------------------------------------------------------------------------

### Method `set()`

#### Usage

    AgentState$set(key, value)

#### Arguments

- `key`:

  String.

- `value`:

  Any value. Update state using reducers

------------------------------------------------------------------------

### Method [`update()`](https://rdrr.io/r/stats/update.html)

#### Usage

    AgentState$update(updates)

#### Arguments

- `updates`:

  List of state updates. Update state from a node's output

------------------------------------------------------------------------

### Method `update_from_node()`

#### Usage

    AgentState$update_from_node(output, node_id)

#### Arguments

- `output`:

  The output from the node.

- `node_id`:

  The ID of the node. Export state for persistence (logic as names)

------------------------------------------------------------------------

### Method `to_list_serializable()`

#### Usage

    AgentState$to_list_serializable()

#### Returns

List.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentState$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize state with a schema and a reducer
state <- AgentState$new(
  initial_data = list(count = 0, history = list()),
  schema = list(count = "numeric", history = "list"),
  reducers = list(history = reducer_append)
)

# Updates to 'history' will now use the append reducer
state$update(list(history = "Event 1"))
message(state$get("history")) # [1] "Event 1"
} # }
```

# Agent State R6 Class

A strongly typed, centrally managed state object for passing data
between nodes in an AgentDAG.

## Public fields

- `data`:

  Environment. Stores state variables.

- `reducers`:

  List. Functions applied to merge updates.

- `schema`:

  List. Expected types for state variables. Initialize AgentState

## Methods

### Public methods

- [`AgentState$new()`](#method-AgentState-new)

- [`AgentState$get()`](#method-AgentState-get)

- [`AgentState$get_all()`](#method-AgentState-get_all)

- [`AgentState$validate()`](#method-AgentState-validate)

- [`AgentState$set()`](#method-AgentState-set)

- [`AgentState$update()`](#method-AgentState-update)

- [`AgentState$clone()`](#method-AgentState-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentState$new(initial_data = list(), reducers = list(), schema = list())

#### Arguments

- `initial_data`:

  List of initial state variables or String.

- `reducers`:

  Named list of reducer functions.

- `schema`:

  Named list of expected types. Get a state variable

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    AgentState$get(key, default = NULL)

#### Arguments

- `key`:

  String.

- `default`:

  Value to return if key not found.

#### Returns

The value. Get all state variables as a list

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

  List of state updates.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentState$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

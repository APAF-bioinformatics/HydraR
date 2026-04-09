# Message Log Base R6 Class

An abstract base class defining the interface for message logging in
HydraR. Subclasses provide concrete storage implementations (Memory,
File, Database).

## Value

A `MessageLog` base object.

## Methods

### Public methods

- [`MessageLog$log()`](#method-MessageLog-log)

- [`MessageLog$get_all()`](#method-MessageLog-get_all)

- [`MessageLog$clone()`](#method-MessageLog-clone)

------------------------------------------------------------------------

### Method [`log()`](https://rdrr.io/r/base/Log.html)

Store a message.

#### Usage

    MessageLog$log(msg)

#### Arguments

- `msg`:

  List. Message object.

#### Returns

The log object (invisibly).

------------------------------------------------------------------------

### Method `get_all()`

Get all logs.

#### Usage

    MessageLog$get_all()

#### Returns

List of logs.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MessageLog$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# This is an abstract base class.
# Use MemoryMessageLog or DuckDBMessageLog instead.
} # }
```

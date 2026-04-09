# Memory Message Log R6 Class

In-memory storage for messages.

## Value

A \`MemoryMessageLog\` object.

## Super class

[`HydraR::MessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MessageLog.md)
-\> `MemoryMessageLog`

## Public fields

- `logs`:

  List. Storage for message logs.

## Methods

### Public methods

- [`MemoryMessageLog$log()`](#method-MemoryMessageLog-log)

- [`MemoryMessageLog$get_all()`](#method-MemoryMessageLog-get_all)

- [`MemoryMessageLog$clone()`](#method-MemoryMessageLog-clone)

------------------------------------------------------------------------

### Method [`log()`](https://rdrr.io/r/base/Log.html)

Store a message.

#### Usage

    MemoryMessageLog$log(msg)

#### Arguments

- `msg`:

  List. Message object.

#### Returns

The log object (invisibly).

------------------------------------------------------------------------

### Method `get_all()`

Get all logs.

#### Usage

    MemoryMessageLog$get_all()

#### Returns

List of logs.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MemoryMessageLog$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
log <- MemoryMessageLog$new()
} # }
```

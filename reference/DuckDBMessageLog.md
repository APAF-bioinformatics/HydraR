# DuckDB Message Log R6 Class

A persistent implementation of `MessageLog` that writes messages to a
centralized DuckDB database. This is the recommended logger for
production and audit-heavy workflows.

## Value

A `DuckDBMessageLog` object.

## Super class

[`HydraR::MessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MessageLog.md)
-\> `DuckDBMessageLog`

## Public fields

- `db_path`:

  String. Path to DuckDB file.

## Methods

### Public methods

- [`DuckDBMessageLog$new()`](#method-DuckDBMessageLog-new)

- [`DuckDBMessageLog$log()`](#method-DuckDBMessageLog-log)

- [`DuckDBMessageLog$get_all()`](#method-DuckDBMessageLog-get_all)

- [`DuckDBMessageLog$clone()`](#method-DuckDBMessageLog-clone)

------------------------------------------------------------------------

### Method `new()`

Finalizer to clean up the cached connection.

Initialize DuckDBMessageLog.

#### Usage

    DuckDBMessageLog$new(db_path = "~/.gemini/memory/bot_history.duckdb")

#### Arguments

- `db_path`:

  String. Path to the DuckDB file. If the file does not exist, it will
  be created upon the first message log. Defaults to the master
  `bot_history.duckdb`.

#### Returns

A new `DuckDBMessageLog` object.

------------------------------------------------------------------------

### Method [`log()`](https://rdrr.io/r/base/Log.html)

Store a message.

#### Usage

    DuckDBMessageLog$log(msg)

#### Arguments

- `msg`:

  List. Message object.

#### Returns

The log object (invisibly).

------------------------------------------------------------------------

### Method `get_all()`

Get all logs.

#### Usage

    DuckDBMessageLog$get_all()

#### Returns

List of logs.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    DuckDBMessageLog$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize a logger pointing to the default HydraR database
audit_log <- DuckDBMessageLog$new(
  db_path = "~/.gemini/memory/audit.duckdb"
)

# Messages are stored in the 'agent_messages' table
} # }
```

# DuckDBSaver Checkpointer

Persistent implementation of the Checkpointer interface using DuckDB.
Supports both direct DBI connections and file paths.

## Value

A \`DuckDBSaver\` R6 object.

## Super class

[`HydraR::Checkpointer`](https://github.com/APAF-bioinformatics/HydraR/reference/Checkpointer.md)
-\> `DuckDBSaver`

## Public fields

- `con`:

  DBIConnection.

- `table_name`:

  String.

## Methods

### Public methods

- [`DuckDBSaver$new()`](#method-DuckDBSaver-new)

- [`DuckDBSaver$put()`](#method-DuckDBSaver-put)

- [`DuckDBSaver$get()`](#method-DuckDBSaver-get)

- [`DuckDBSaver$clone()`](#method-DuckDBSaver-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize DuckDBSaver

#### Usage

    DuckDBSaver$new(con = NULL, db_path = NULL, table_name = "agent_checkpoints")

#### Arguments

- `con`:

  DBIConnection. Optional if db_path is provided.

- `db_path`:

  String path to DuckDB file. Optional if con is provided.

- `table_name`:

  Name of the table to store checkpoints in. Save state

------------------------------------------------------------------------

### Method `put()`

#### Usage

    DuckDBSaver$put(thread_id, state)

#### Arguments

- `thread_id`:

  String.

- `state`:

  AgentState object. Load state

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    DuckDBSaver$get(thread_id)

#### Arguments

- `thread_id`:

  String.

#### Returns

AgentState object or NULL.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    DuckDBSaver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
saver <- DuckDBSaver$new(db_path = "checkpoints.duckdb")
} # }
```

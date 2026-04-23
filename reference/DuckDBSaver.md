# DuckDBSaver Checkpointer

A production-grade `Checkpointer` that utilizes DuckDB for
high-performance state persistence. Supports BLOB storage of serialized
R objects and concurrent access patterns.

## Value

A `DuckDBSaver` R6 object.

## Super class

[`HydraR::Checkpointer`](https://APAF-bioinformatics.github.io/HydraR/reference/Checkpointer.md)
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

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize DuckDBSaver

#### Usage

    DuckDBSaver$new(con = NULL, db_path = NULL, table_name = "agent_checkpoints")

#### Arguments

- `con`:

  DBIConnection. An existing DBI connection to a DuckDB instance.

- `db_path`:

  String. Path to a DuckDB file. If provided, the driver will handle the
  connection internally.

- `table_name`:

  String. The name of the table used to store checkpoints. Defaults to
  `"agent_checkpoints"`. Save state

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
# 1. Production-ready persistence using DuckDB
saver <- DuckDBSaver$new(
  db_path = "storage/hydrar_main.duckdb",
  table_name = "workflow_checkpoints"
)

# 2. Orchestrate a long-running DAG
dag <- dag_create(checkpointer = saver)
dag$run(thread_id = "genomic_alignment_job_42")

# 3. Query the internal storage directly if needed
library(DBI)
DBI::dbGetQuery(saver$con, "SELECT thread_id, updated_at FROM workflow_checkpoints")
} # }
```

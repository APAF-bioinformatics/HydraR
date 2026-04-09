# Create an Agent Graph

Initializes a new `AgentDAG` object. This is the primary entry point for
building orchestration workflows either programmatically or from
definitions.

## Usage

``` r
dag_create(message_log = NULL)
```

## Arguments

- message_log:

  MessageLog. An optional `MessageLog` R6 object (e.g.,
  `MemoryMessageLog` or `DuckDBMessageLog`) used to capture all
  inter-node communication for auditing and debugging.

## Value

An `AgentDAG` R6 object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic DAG creation
dag <- dag_create()

# Creation with a persistent DuckDB audit log
# Recommended for production workflows to ensure audutability.
log <- DuckDBMessageLog$new(db_path = "audit_trail.duckdb")
dag <- dag_create(message_log = log)
} # }
```

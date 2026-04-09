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
library(HydraR)

# 1. Simple Audit-only DAG
dag <- dag_create()

# 2. Production DAG with persistent DuckDB audit log and custom metadata
# This pattern ensures every agent interaction is recorded for reproducibility.
log <- DuckDBMessageLog$new(db_path = "audit_trail.duckdb")
dag <- dag_create(message_log = log)

# 3. Advanced setup with a pre-configured memory saver
saver <- MemorySaver$new()
cp <- Checkpointer$new(saver = saver)
# Note: Checkpointer is typically assigned to the DAG after creation
dag$checkpointer <- cp
} # }
```

# HydraR Useful Tools Manual

This manual describes the utility and diagnostic scripts located in the `/tools/` directory. These tools are designed for project maintenance, performance benchmarking, and deep state inspection.

---

## 1. DuckDB & State Diagnostics
These tools allow you to peer into the persistent state managed by `DuckDBSaver`.

| Script | Purpose |
| :--- | :--- |
| **`inspect_duckdb.R`** | Core utility to list tables and peek at the most recent state entries. |
| **`peek_tables.R`** | Low-level SQL inspection of the database schema and row counts. |
| **`debug_duckdb.R`** | Diagnostic script to test connection stability and write/read latency. |
| **`peek_duckdb_trace.R`** | Extracts the versioned state history for a specific `thread_id` to trace logic evolution. |

---

## 2. Performance & Benchmarking

| Script | Purpose |
| :--- | :--- |
| **`benchmark_duckdb.R`** | Runs massive parallel write/read operations (via `furrr`) to stress-test the state checkpointer. |
| **`monitor_re_travel.R`** | Real-time monitoring for long-running workflows (specifically used during the Hong Kong travel vignette execution). |

---

## 3. Integration & Model Management

| Script | Purpose |
| :--- | :--- |
| **`check_models.R`** | A quick connectivity test for `GeminiAPIDriver`, `AnthropicCLIDriver`, and others to ensure API keys are valid. |

---

## 4. Internal Cleanup & Legacy
These scripts are intended for maintenance and managing historical agent sessions.

| Script | Purpose |
| :--- | :--- |
| **`list_jules_sessions.R`** | Lists historical sessions from the legacy Jules driver to aid in repository cleanup and state pruning. |

---

## 5. Usage Instructions

To run any of these tools from the project root:

```bash
Rscript tools/inspect_duckdb.R
```

> [!NOTE]
> Most diagnostic tools expect the standard `HydraR` environment. Ensure your `GOOGLE_API_KEY` or `db_path` is correctly set before execution.

---
<!-- APAF Bioinformatics | HydraR | Useful Tools Manual | 2026-04-03 -->

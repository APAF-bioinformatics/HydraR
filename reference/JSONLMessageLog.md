# JSONL Message Log R6 Class

A file-based implementation of `MessageLog` that appends messages to a
JSON Lines file. This implementation is safe for parallel execution
across git worktrees as it uses atomic line appending.

## Value

A `JSONLMessageLog` object.

## Super class

[`HydraR::MessageLog`](https://APAF-bioinformatics.github.io/HydraR/reference/MessageLog.md)
-\> `JSONLMessageLog`

## Public fields

- `path`:

  String. Path to JSONL file.

## Methods

### Public methods

- [`JSONLMessageLog$new()`](#method-JSONLMessageLog-new)

- [`JSONLMessageLog$log()`](#method-JSONLMessageLog-log)

- [`JSONLMessageLog$get_all()`](#method-JSONLMessageLog-get_all)

- [`JSONLMessageLog$clone()`](#method-JSONLMessageLog-clone)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Initialize JSONLMessageLog.

#### Usage

    JSONLMessageLog$new(path = tempfile(fileext = ".jsonl"))

#### Arguments

- `path`:

  String. The output file path for the JSON Lines log. Defaults to a
  temporary file.

------------------------------------------------------------------------

### Method [`log()`](https://rdrr.io/r/base/Log.html)

Store a message (atomic append).

#### Usage

    JSONLMessageLog$log(msg)

#### Arguments

- `msg`:

  List. Message object.

------------------------------------------------------------------------

### Method `get_all()`

Get all logs.

#### Usage

    JSONLMessageLog$get_all()

#### Returns

List of logs.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    JSONLMessageLog$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Create a file-based logger using JSONL format
file_log <- JSONLMessageLog$new(path = "logs/pipeline_audit.jsonl")

# 2. Orchestrate a DAG with file-level auditing
dag <- dag_create(message_log = file_log)
dag$run(initial_state = list(x = 1))

# 3. Read back the logs from the file
logs <- file_log$get_all()
print(logs[[1]])
} # }
```

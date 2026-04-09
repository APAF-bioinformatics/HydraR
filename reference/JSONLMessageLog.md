# JSONL Message Log R6 Class

A file-based implementation of `MessageLog` that appends messages to a
JSON Lines file. This implementation is safe for parallel execution
across git worktrees as it uses atomic line appending.

## Value

A `JSONLMessageLog` object.

## Super class

[`HydraR::MessageLog`](https://github.com/APAF-bioinformatics/HydraR/reference/MessageLog.md)
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

### Method `new()`

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
# Create a logger that writes to a specific project file
file_log <- JSONLMessageLog$new(path = "workflow_audit.jsonl")

# Executing a DAG with this logger will populate the file
dag <- dag_create(message_log = file_log)
} # }
```

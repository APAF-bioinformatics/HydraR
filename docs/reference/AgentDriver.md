# Agent Driver R6 Class

Abstract base class for CLI-based LLM drivers.

## Value

An \`AgentDriver\` R6 object.

## Public fields

- `id`:

  String. Unique identifier for the driver.

- `provider`:

  String. Provider name (e.g., "google", "ollama").

- `model_name`:

  String. The specific model identifier.

- `supported_opts`:

  Character vector. Allowed CLI option names.

- `validation_mode`:

  String. Either "warning" or "strict".

- `working_dir`:

  String. Optional path to the working directory/worktree. Initialize
  AgentDriver

## Methods

### Public methods

- [`AgentDriver$new()`](#method-AgentDriver-new)

- [`AgentDriver$get_capabilities()`](#method-AgentDriver-get_capabilities)

- [`AgentDriver$exec_in_dir()`](#method-AgentDriver-exec_in_dir)

- [`AgentDriver$call()`](#method-AgentDriver-call)

- [`AgentDriver$validate_cli_opts()`](#method-AgentDriver-validate_cli_opts)

- [`AgentDriver$format_cli_opts()`](#method-AgentDriver-format_cli_opts)

- [`AgentDriver$clone()`](#method-AgentDriver-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentDriver$new(
      id,
      provider = "unknown",
      model_name = "unknown",
      validation_mode = "warning",
      working_dir = NULL
    )

#### Arguments

- `id`:

  Unique identifier.

- `provider`:

  String. Provider name.

- `model_name`:

  String. Model identifier.

- `validation_mode`:

  String. "warning" or "strict".

- `working_dir`:

  String. Optional working directory. Get Driver Capabilities

------------------------------------------------------------------------

### Method `get_capabilities()`

#### Usage

    AgentDriver$get_capabilities()

#### Returns

List of logicals. Execute Command in Working Directory

------------------------------------------------------------------------

### Method `exec_in_dir()`

Safely executes a system command within the specified 'working_dir'
using 'withr::with_dir' to ensure the original CWD is restored.

#### Usage

    AgentDriver$exec_in_dir(command, args, ...)

#### Arguments

- `command`:

  String. The command to run.

- `args`:

  Character vector. Command arguments.

- `...`:

  Additional arguments passed to system2.

#### Returns

Result of system2 call. Call the LLM

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

#### Usage

    AgentDriver$call(prompt, model = NULL, cli_opts = list(), ...)

#### Arguments

- `prompt`:

  String. The prompt to send.

- `model`:

  String. Optional model override.

- `cli_opts`:

  List. Named list of CLI options.

- `...`:

  Additional arguments.

#### Returns

String. Cleaned response from the LLM. Validate CLI Options

------------------------------------------------------------------------

### Method `validate_cli_opts()`

#### Usage

    AgentDriver$validate_cli_opts(cli_opts)

#### Arguments

- `cli_opts`:

  List. Named list to validate.

#### Returns

Invisible TRUE if valid. Format CLI Options

------------------------------------------------------------------------

### Method `format_cli_opts()`

#### Usage

    AgentDriver$format_cli_opts(cli_opts = list())

#### Arguments

- `cli_opts`:

  List. Named list to format.

#### Returns

Character vector of CLI flags.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentDriver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
driver <- AgentDriver$new(id = "test", provider = "mock")
} # }
```

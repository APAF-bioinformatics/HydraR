# Bash Execution Node

Executes a raw bash script. Can run within an isolated worktree if
configured.

## Super class

[`HydraR::AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
-\> `AgentBashNode`

## Public fields

- `script`:

  Character string or Function. The bash script to execute.

- `env_vars`:

  Named list. Environment variables to inject. Initialize

## Methods

### Public methods

- [`AgentBashNode$new()`](#method-AgentBashNode-new)

- [`AgentBashNode$run()`](#method-AgentBashNode-run)

- [`AgentBashNode$clone()`](#method-AgentBashNode-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentBashNode$new(id, label = NULL, script, env_vars = list(), params = list())

#### Arguments

- `id`:

  Node ID

- `label`:

  Node Label

- `script`:

  String or Function(state) returning a string.

- `env_vars`:

  Named list of environment variables

- `params`:

  List of standard Node parameters Run Bash Execution

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentBashNode$run(state, working_dir = NULL)

#### Arguments

- `state`:

  AgentState object.

- `working_dir`:

  Directory context for execution.

#### Returns

List with output, status_code, and success flag.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentBashNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

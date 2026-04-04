# Python Execution Node

Executes a python script via system python or reticulate.

## Super class

[`HydraR::AgentNode`](https://github.com/APAF-bioinformatics/HydraR/reference/AgentNode.md)
-\> `AgentPythonNode`

## Public fields

- `script`:

  Character string or Function. The python script to execute.

- `engine`:

  Character. Execution engine ("system2" or "reticulate").

## Methods

### Public methods

- [`AgentPythonNode$new()`](#method-AgentPythonNode-new)

- [`AgentPythonNode$run()`](#method-AgentPythonNode-run)

- [`AgentPythonNode$clone()`](#method-AgentPythonNode-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    AgentPythonNode$new(
      id,
      label = NULL,
      script,
      engine = "system2",
      params = list()
    )

#### Arguments

- `id`:

  Node ID

- `label`:

  Node Label

- `script`:

  String or Function(state) returning a string.

- `engine`:

  "system2" (isolated process) or "reticulate" (inline bindings).

- `params`:

  List of standard Node parameters Run Python Execution

------------------------------------------------------------------------

### Method `run()`

#### Usage

    AgentPythonNode$run(state, working_dir = NULL)

#### Arguments

- `state`:

  AgentState object.

- `working_dir`:

  Directory context for execution.

#### Returns

List with output, success flag, and optionally result variables.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentPythonNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

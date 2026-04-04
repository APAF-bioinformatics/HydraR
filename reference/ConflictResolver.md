# Git Conflict Resolver R6 Class

Handles semantic or git-level conflicts during branch merges. Used by
Conflict Harmonizer nodes.

## Value

A \`ConflictResolver\` R6 object.

## Public fields

- `strategy`:

  String. "llm", "human", or "ours".

- `driver`:

  AgentDriver. The driver to use for "llm" strategy.

## Methods

### Public methods

- [`ConflictResolver$new()`](#method-ConflictResolver-new)

- [`ConflictResolver$resolve()`](#method-ConflictResolver-resolve)

- [`ConflictResolver$clone()`](#method-ConflictResolver-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize ConflictResolver

#### Usage

    ConflictResolver$new(strategy = "llm", driver = NULL)

#### Arguments

- `strategy`:

  Conflict resolution strategy.

- `driver`:

  Optional LLM driver for semantic resolution.

#### Returns

A new \`ConflictResolver\` object. Resolve a Conflict

------------------------------------------------------------------------

### Method `resolve()`

#### Usage

    ConflictResolver$resolve(repo_root, branch_a, branch_b, files)

#### Arguments

- `repo_root`:

  Path to repo.

- `branch_a`:

  Branch A.

- `branch_b`:

  Branch B (usually base).

- `files`:

  List of conflicting files.

#### Returns

List with status and details.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ConflictResolver$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

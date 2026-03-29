# Git Worktree Manager R6 Class

Manages the lifecycle of isolated git worktrees for parallel DAG
branches. This ensures that each parallel worker has its own filesystem
checkout, preventing file-level conflicts between concurrent CLI agents.

## Value

A \`WorktreeManager\` R6 object.

## Public fields

- `repo_root`:

  String. Path to the main git repository.

- `worktrees`:

  List. Active worktrees indexed by node_id.

- `base_branch`:

  String. The branch to fork worktrees from.

- `branch_prefix`:

  String. Prefix for auto-generated branch names.

- `cleanup_policy`:

  String. "auto", "none", or "aggressive".

- `thread_id`:

  String. Optional identifier for the current DAG execution. Initialize
  WorktreeManager

## Methods

### Public methods

- [`WorktreeManager$new()`](#method-WorktreeManager-new)

- [`WorktreeManager$create()`](#method-WorktreeManager-create)

- [`WorktreeManager$get_path()`](#method-WorktreeManager-get_path)

- [`WorktreeManager$get_branch()`](#method-WorktreeManager-get_branch)

- [`WorktreeManager$remove_worktree()`](#method-WorktreeManager-remove_worktree)

- [`WorktreeManager$delete_branch()`](#method-WorktreeManager-delete_branch)

- [`WorktreeManager$remove()`](#method-WorktreeManager-remove)

- [`WorktreeManager$cleanup_node()`](#method-WorktreeManager-cleanup_node)

- [`WorktreeManager$cleanup()`](#method-WorktreeManager-cleanup)

- [`WorktreeManager$branch_exists()`](#method-WorktreeManager-branch_exists)

- [`WorktreeManager$is_repo_clean()`](#method-WorktreeManager-is_repo_clean)

- [`WorktreeManager$clone()`](#method-WorktreeManager-clone)

------------------------------------------------------------------------

### Method `new()`

#### Usage

    WorktreeManager$new(
      repo_root = getwd(),
      base_branch = "main",
      branch_prefix = "hydra",
      cleanup_policy = "auto",
      thread_id = NULL
    )

#### Arguments

- `repo_root`:

  Path to the main repository. Defaults to getwd().

- `base_branch`:

  Branch to branch from. Defaults to "main".

- `branch_prefix`:

  Prefix for new branches.

- `cleanup_policy`:

  Cleanup strategy.

- `thread_id`:

  Optional execution identifier.

#### Returns

A new \`WorktreeManager\` object. Create an Isolated Worktree

------------------------------------------------------------------------

### Method `create()`

#### Usage

    WorktreeManager$create(node_id, branch_name = NULL, fail_if_dirty = TRUE)

#### Arguments

- `node_id`:

  String. Identifier for the DAG node.

- `branch_name`:

  Optional specific branch name.

- `fail_if_dirty`:

  Logical. Whether to stop if repo has uncommitted changes.

#### Returns

String. The absolute path to the new worktree. Get Worktree Path for a
Node

------------------------------------------------------------------------

### Method `get_path()`

#### Usage

    WorktreeManager$get_path(node_id)

#### Arguments

- `node_id`:

  Node identifier.

#### Returns

String path or NULL. Get Worktree Branch for a Node

------------------------------------------------------------------------

### Method `get_branch()`

#### Usage

    WorktreeManager$get_branch(node_id)

#### Arguments

- `node_id`:

  Node identifier.

#### Returns

String branch name or NULL. Remove the Physical Worktree Directory

------------------------------------------------------------------------

### Method `remove_worktree()`

#### Usage

    WorktreeManager$remove_worktree(node_id, force = TRUE)

#### Arguments

- `node_id`:

  Node identifier.

- `force`:

  Logical. Force removal.

#### Returns

Logical (invisibly). Delete the branch and unregister node

------------------------------------------------------------------------

### Method `delete_branch()`

#### Usage

    WorktreeManager$delete_branch(node_id)

#### Arguments

- `node_id`:

  Node identifier.

#### Returns

Logical (invisibly). Legacy remove method for backward compatibility

------------------------------------------------------------------------

### Method [`remove()`](https://rdrr.io/r/base/rm.html)

#### Usage

    WorktreeManager$remove(node_id, force = TRUE, delete_branch = FALSE)

#### Arguments

- `node_id`:

  Node identifier.

- `force`:

  Logical. Force removal.

- `delete_branch`:

  Logical. Delete the branch.

#### Returns

NULL (called for side effect). Cleanup Worktree based on Policy and
Status

------------------------------------------------------------------------

### Method `cleanup_node()`

#### Usage

    WorktreeManager$cleanup_node(node_id, status = "success")

#### Arguments

- `node_id`:

  Node identifier.

- `status`:

  String. "success", "failure", or "conflict".

#### Returns

NULL (called for side effect). Cleanup All Worktrees

------------------------------------------------------------------------

### Method `cleanup()`

Removes all worktrees managed by this instance.

#### Usage

    WorktreeManager$cleanup()

#### Returns

Logical (invisibly). Check if a branch exists

------------------------------------------------------------------------

### Method `branch_exists()`

#### Usage

    WorktreeManager$branch_exists(branch)

#### Arguments

- `branch`:

  String.

#### Returns

Logical. Check if the Repository is Clean

------------------------------------------------------------------------

### Method `is_repo_clean()`

#### Usage

    WorktreeManager$is_repo_clean()

#### Returns

Logical.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    WorktreeManager$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
wt_manager <- WorktreeManager$new(repo_root = getwd())
} # }
```

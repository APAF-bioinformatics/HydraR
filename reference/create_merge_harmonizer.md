# Create a Merge Harmonizer Node

Factory function to create an AgentLogicNode that merges parallel git
branches back into the base branch.

## Usage

``` r
create_merge_harmonizer(
  id = "merge_harmonizer",
  strategy = "sequential",
  conflict_resolver = NULL
)
```

## Arguments

- id:

  String. Node identifier.

- strategy:

  String. "sequential" or "octopus".

- conflict_resolver:

  ConflictResolver. Optional custom resolver.

## Value

An \`AgentLogicNode\` R6 object.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. Create a harmonizer with a specific conflict resolution strategy
resolver <- ConflictResolver$new(strategy = "human")
merger <- create_merge_harmonizer(
  id = "global_merger",
  strategy = "sequential",
  conflict_resolver = resolver
)

# 2. This node is then added to a DAG that uses parallel execution
# and a WorktreeManager in its state.
} # }
```

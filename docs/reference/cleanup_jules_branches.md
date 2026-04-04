# Cleanup Stale GitHub Branches

Identifies and optionally deletes stale remote branches on GitHub.
Specifically targets branches authored by 'google-labs-jules\[bot\]'
that have been inactive beyond a specified threshold, or any branch
already merged into the main branch.

## Usage

``` r
cleanup_jules_branches(
  repo_root = getwd(),
  threshold_hours = 24,
  dry_run = TRUE,
  verbose = TRUE
)
```

## Arguments

- repo_root:

  String. Path to the git repository. Defaults to \`getwd()\`.

- threshold_hours:

  Numeric. Inactivity threshold for Jules's branches (hours). Defaults
  to 24.

- dry_run:

  Logical. If TRUE (default), identifies candidates but does not perform
  deletion.

- verbose:

  Logical. If TRUE, prints detailed status messages.

## Value

A character vector of branches identified for deletion.

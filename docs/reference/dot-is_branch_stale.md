# Helper to check if a branch is stale

Helper to check if a branch is stale

## Usage

``` r
.is_branch_stale(b, repo_root, jules_bot_email, threshold_hours, now, verbose)
```

## Arguments

- b:

  String. Branch name

- repo_root:

  String. Path to the git repository

- jules_bot_email:

  String. Email of bot.

- threshold_hours:

  Numeric. Inactivity threshold.

- now:

  Integer. Current Unix timestamp.

- verbose:

  Logical. If TRUE, logs details.

## Value

Logical TRUE if branch should be deleted.

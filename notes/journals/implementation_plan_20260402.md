# Merge All Open Pull Requests

The goal is to consolidate and merge all 8 open pull requests in the `APAF-bioinformatics/HydraR` repository into the `main` branch. Most of these PRs are currently marked as "CONFLICTING" or have CI failures.

## User Review Required

> [!IMPORTANT]
> **Conflict Resolution**: 7 out of 8 PRs have conflicts. I will merge `main` into each PR branch locally, resolve conflicts, and then merge the PR.
> **CI Failure in #25**: PR #25 ("Remove unactionable tracking comment") is failing on `ubuntu-latest (oldrel-1)`. I will verify if this failure is caused by the change or if it's an environment issue before merging.
> **Sequential Merging**: To minimize conflict ripple effects, I will merge them in a logical order (Docs -> Fixes -> Security -> Testing -> Backup).

## Proposed Order of Operations

### 1. Documentation & Low-Risk Changes
- **PR #24**: `docs: change Reporting Bugs heading to Reporting Issues`
- **PR #25**: `Remove unactionable tracking comment in dag.R` (Investigate failure first)

### 2. Core Logic & Security Fixes
- **PR #26**: `fix: Persist DAG execution results on chunked runs`
- **PR #28**: `🔒 Fix command injection in driver CLI execution`

### 3. Testing Infrastructure
- **PR #27**: `🧪 test(drivers): add error path test for driver network failures`
- **PR #29**: `test: Reword comment in test-software_bug_assistant.R`
- **PR #30**: `🧪 Add test for worktree cleanup when driver execution fails`

### 4. Cleanup/Refactoring
- **PR #18**: `Backup main` (Contains `test-jules_api.R` and significant API surface changes)

---

## Verification Plan

### Automated Tests
- Run `devtools::check()` after each merge.
- Run `testthat::test_local()` to ensure all tests pass.
- Verify security fix in #28 specifically.

### Manual Verification
- Verify the `vignettes/` render correctly if applicable.
- Confirm PRs are closed on GitHub.

<!-- APAF Bioinformatics | HydraR | Approved | 2026-04-02 -->

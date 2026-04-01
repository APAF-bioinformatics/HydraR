# HydraR: Road to rOpenSci Submission

This task list outlines the remaining steps to achieve **rOpenSci** software review readiness.

## 🏁 Phase 1: Community & Inclusion (Compulsory)
- [ ] Create `CONTRIBUTING.md` (rOpenSci guidelines).
- [ ] Create `CONDUCT.md` (Code of Conduct).
- [ ] Add `LICENSE.md` as a separate file (or symbolic link from `LICENSE`).
- [ ] Populate `NEWS.md` for initial release v0.1.0.

## 🏷️ Phase 2: Metadata & Documentation
- [ ] Update `DESCRIPTION` with author ORCIDs.
- [ ] Refine `README.md` with:
    - [ ] Clear "Installation" section.
    - [ ] "Getting Started" segment for first-time users.
    - [ ] Badges for tests, coverage, and rOpenSci (placeholders).

## 💎 Phase 3: Code Quality & Styling
- [ ] Run `styler::style_pkg()` to ensure consistency.
- [ ] Run `lintr::lint_package()` and resolve critical warnings.
- [ ] Ensure all exported functions have `@examples`.
- [ ] Ensure all exported functions have `@return` values.

## 📝 Phase 3.5: Publications & Vignettes
- [ ] Add a vignette example that tests restart functionality using duckdb. Option to create reprex using duckdb, fix code and restart. Keep it simple to fit into the Journal of Open Source Software (JOSS) word limit, but highlight the use of duckdb to restart.

## 🛠️ Phase 4: CI/CD & Final Checks
- [ ] Initialize `pkgdown` website configuration.
- [ ] Set up GitHub Actions for:
    - [ ] R-CMD-check (Windows, MacOS, Linux).
    - [ ] Code Coverage (Codecov).
    - [ ] Pkgdown build/deploy.
- [ ] Run `devtools::check(remote = TRUE, manual = TRUE)`.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-29 -->

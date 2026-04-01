# Contributing to HydraR

Thank you for your interest in contributing to `HydraR`! We welcome contributions from the community to help make this framework more robust and useful for agentic research.

## How to Contribute

### Reporting Issues
- Please check the [existing issues](https://github.com/APAF-bioinformatics/HydraR/issues) before opening a new one.
- Use a clear and descriptive title.
- Provide a minimal reproducible example (reprex) if possible.
- Include information about your R version, OS, and package versions.

### Suggesting Enhancements
- Open a new issue to discuss your idea before starting implementation.
- Explain the use case and why the feature would be beneficial.

### Pull Requests
- Fork the repository and create your branch from `main`.
- Follow the [APAF Bioinformatics coding standards](https://github.com/APAF-bioinformatics/HydraR#coding-standards).
- Ensure all new functions are documented with `roxygen2`.
- Add tests for any new functionality in `tests/testthat/`.
- Ensure `devtools::check()` passes without errors or warnings.
- Run `styler::style_pkg()` before submitting.

## Use of Generative AI in Contributions

We welcome contributions involving the use of Generative AI tools. However, to maintain the integrity and quality of the scientific software, all contributors must:
- **Disclose**: Mention in the Pull Request if AI tools (e.g., GitHub Copilot, ChatGPT, Antigravity) were used to generate any part of the contribution.
- **Verify**: Affirm that all AI-generated code, documentation, and tests have been manually reviewed, tested, and verified for correctness.
- **Responsibility**: The human contributor takes full responsibility for the code submitted.

## Style Guidelines
We follow the Tidyverse style guide. Please run `styler::style_pkg()` on your changes to ensure consistency with the rest of the package.

## Code of Conduct
Please note that the `HydraR` project is released with a [Contributor Code of Conduct](CONDUCT.md). By contributing to this project, you agree to abide by its terms.

---
<!-- APAF Bioinformatics | HydraR | Approved | 2026-03-29 -->

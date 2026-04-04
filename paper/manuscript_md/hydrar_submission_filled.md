<!---
Below, please enter values for (1) submitting author GitHub handle (replacing "@github_handle@); and (2) Repository URL (replacing "https://repourl"). Values for additional package authors may also be specified, replacing "@github_handle1", "@github_handle2" - delete these if not needed. DO NOT DELETE HTML SYMBOLS (everything between "<!" and ">"). Replace only "@github_handle" and "https://repourl". This comment may be deleted once it has been read and understood.
--->

Submitting Author Name: Ignatius Pang
Submitting Author Github Handle: <!--author1-->@ignatiuspang<!--end-author1-->
Other Package Authors Github handles: <!--author-others-->@aidantay<!--end-author-others-->
Repository:  <!--repourl-->https://github.com/APAF-bioinformatics/HydraR<!--end-repourl-->
Version submitted: 0.1.0
Submission type: <!--submission-type-->Standard<!--end-submission-type-->
Editor: <!--editor--> TBD <!--end-editor-->
Reviewers: <!--reviewers-list--> TBD <!--end-reviewers-list-->
<!--due-dates-list--><!--end-due-dates-list-->
Archive: TBD
Version accepted: TBD
Language: <!--language-->en<!--end-language-->

---

-   Paste the full DESCRIPTION file inside a code block below:

```
Package: HydraR
Type: Package
Title: Stateful Agentic Orchestration for Scientific Reproducibility
Version: 0.1.0
Authors@R: 
    c(person(given = c("Chi", "Nam", "Ignatius"),
             family = "Pang",
             role = c("aut", "cre"),
             email = "ignatius.pang@mq.edu.au",
             comment = c(ORCID = "0000-0001-9703-5741")),
      person(given = "Aidan",
             family = "Tay",
             role = c("aut", "cre"),
             comment = c(ORCID = "0000-0003-1315-4896")),
      person(given = c("APAF", "Agentic"),
             family = "Workflow",
             role = "ctb"))
Description: A high-performance framework for orchestrating complex 
    agentic workflows in R, specifically designed for scientific 
    reproducibility and auditability. HydraR provides a robust, 
    state-managed engine for Directed Acyclic Graphs (DAGs) and 
    iterative state machines, prioritizing CLI-native LLM 
    interactions (e.g., Gemini, Claude, Copilot) and hardened 
    state persistence (DuckDB/SQLite). It features isolated 
    execution via Git Worktrees for parallel file-modifying 
    tasks, autonomous quality control through integrated 
    auditors, and human-readable visualization using Mermaid.js. 
    Ideal for creating auditable, resumable research assistants 
    and complex bioinformatics pipelines.
URL: https://github.com/APAF-bioinformatics/HydraR
BugReports: https://github.com/APAF-bioinformatics/HydraR/issues
License: LGPL (>= 3)
Encoding: UTF-8
RoxygenNote: 7.3.3
Depends: 
    R (>= 4.1.0)
Imports: 
    DBI,
    digest,
    furrr,
    igraph,
    jsonlite,
    purrr,
    R6,
    yaml
Suggests: 
    testthat (>= 3.0.0),
    duckdb,
    knitr,
    rmarkdown,
    httr2,
    future,
    devtools,
    withr,
    reticulate,
    DiagrammeR
VignetteBuilder: knitr
Config/testthat/edition: 3
```

## Scope

- Please indicate which category or categories from our [package fit policies](https://devguide.ropensci.org/softwarereview_policies.html#package-categories) this package falls under: (Please check an appropriate box below. If you are unsure, we suggest you make a pre-submission inquiry.):

	- [ ] data retrieval
	- [ ] data extraction
	- [ ] data munging
	- [ ] data deposition
    - [x] data validation and testing
	- [x] workflow automation
	- [ ] version control
	- [ ] citation management and bibliometrics
	- [x] scientific software wrappers
	- [x] field and lab reproducibility tools
	- [ ] database software bindings
	- [ ] geospatial data
	- [ ] translation
    - [ ] rOpenSci internal tools 

- Explain how and why the package falls under these categories (briefly, 1-2 sentences):

    HydraR provides a stateful, auditable engine for orchestrating complex agentic workflows, specifically targeting scientific reproducibility via Git worktree isolation and persistent DuckDB/SQLite checkpointing. It acts as a robust wrapper for LLM CLIs tailored for bioinformatics research.

-   Who is the target audience and what are scientific applications of this package?

    The target audience includes bioinformaticians, research software engineers, and data scientists building multi-agent systems for automated data analysis, code refactoring, and large-scale literature synthesis.

-   Are there other R packages that accomplish the same thing? If so, how does yours differ or meet [our criteria for best-in-category](https://ropensci.github.io/dev_guide/policies.html#overlap)?

    While 'ellmer' focuses on high-level API convenience and 'gptstudio' on IDE integration, HydraR is uniquely "State-First" and "CLI-First". It enables complex research pipelines with full audit trails and safe parallel file modifications using Git worktrees, which are critical for reproducible scientific coding.

-   (If applicable) Does your package comply with our [guidance around _Ethics, Data Privacy and Human Subjects Research_](https://devguide.ropensci.org/policies.html#ethics-data-privacy-and-human-subjects-research)?

    Yes.

-   If you made a pre-submission inquiry, please paste the link to the corresponding issue, forum post, or other discussion, or `@tag` the editor you contacted.

    N/A

-   Explain reasons for any [`pkgcheck` items](https://docs.ropensci.org/pkgcheck/) which your package is unable to pass.

    The package currently passes `R CMD check` with 0 Errors and 0 Warnings. Minor NOTEs regarding hidden developer files (`.github`, `.lintr`) are intentional for repository management.

## Technical checks

Confirm each of the following by checking the box.

- [x] I have read the [rOpenSci packaging guide](https://devguide.ropensci.org/building.html).
- [x] I have read the [author guide](https://devguide.ropensci.org/softwarereview_author.html) and I expect to maintain this package for at least 2 years or to find a replacement.

This package:

- [x] does not violate the Terms of Service of any service it interacts with.
- [x] has a CRAN and OSI accepted license.
- [x] contains a [README with instructions for installing the development version](https://ropensci.github.io/dev_guide/building.html#readme).
- [x] includes [documentation with examples for all functions, created with roxygen2](https://ropensci.github.io/dev_guide/building.html#documentation).
- [x] contains a vignette with examples of its essential functions and uses.
- [x] has a [test suite](https://ropensci.github.io/dev_guide/building.html#testing).
- [x] has [continuous integration](https://ropensci.github.io/dev_guide/ci.html), including reporting of test coverage.

## Use of Generative AI

- [x] Generative AI tools were used to produce some of the material in this submission.

If so, please describe usage, and include links to any relevant aspects of your repository. 

The core R6 architecture, state-management patterns, and Git worktree isolation strategies were designed and authored by the human authors (Ignatius Pang and Aidan Tay) during a focused **4–5 day architectural sprint** and then **rigorously tested manually**. AI (Antigravity) was strategically employed for implementing logic blocks, unit tests, and documentation, following a rigorous "Human-in-the-loop" pattern where every line was manually reviewed and verified. Detailed disclosure is available in **[agents.md](agents.md)** and **[DESIGN.md](DESIGN.md)**.

## Publication options

- [x] Do you intend for this package to go on CRAN?
- [ ] Do you intend for this package to go on Bioconductor?

- [ ] Do you wish to submit an Applications Article about your package to [Methods in Ecology and Evolution](http://besjournals.onlinelibrary.wiley.com/hub/journal/10.1111/(ISSN)2041-210X/)? If so:

<details>
<summary>MEE Options</summary>

- [ ] The package is novel and will be of interest to the broad readership of the journal.
- [ ] The manuscript describing the package is no longer than 3000 words.
- [ ] You intend to archive the code for the package in a long-term repository which meets the requirements of the journal (see [MEE's Policy on Publishing Code](https://besjournals.onlinelibrary.wiley.com/hub/journal/2041210x/policyonpublishingcode.html))

</details>

*Note: We also intend to submit to JOSS as the primary scholarly venue for the software.*

## Code of conduct

- [x] I agree to abide by [rOpenSci's Code of Conduct](https://ropensci.org/code-of-conduct/) during the review process and in maintaining my package should it be accepted.


R version 4.5.0 (2025-04-11) -- "How About a Twenty-Six"
Copyright (C) 2025 The R Foundation for Statistical Computing
Platform: aarch64-apple-darwin20

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> library(pkgcheck); check <- pkgcheck(); print(check); saveRDS(check, "notes/submission/pkgcheck_results.rds")
Preparing: covr
Preparing: cyclocomp
Preparing: description
Preparing: lintr
Preparing: namespace
Preparing: rcmdcheck

── HydraR 0.1.0 ────────────────────────────────────────────────────────────────

✔ Package name is available
✔ has a 'contributing' file.
✖ The following functions have no documented return values: [AgentBashNode, AgentNode, AgentPythonNode, AgentTool, Checkpointer, AnthropicCLIDriver, CopilotCLIDriver, DuckDBMessageLog, GeminiCLIDriver, JSONLMessageLog, MemoryMessageLog, MemorySaver, MessageLog, OllamaDriver, RDSSaver, RestrictedState]
✔ uses 'roxygen2'.
✔ 'DESCRIPTION' has a URL field.
✔ 'DESCRIPTION' has a BugReports field.
✔ Package has at least one HTML vignette
✖ These functions do not have examples: [add_llm_node, add_logic_node, AgentBashNode, AgentNode, AgentPythonNode, AgentTool, AnthropicAPIDriver, Checkpointer, AnthropicCLIDriver, ConflictResolver, CopilotCLIDriver, dag_add_llm_node, dag_add_logic_node, dag_create, DriverRegistry, DuckDBMessageLog, extract_r_code_advanced, format_toolset, GeminiAPIDriver, GeminiCLIDriver, get_driver_registry, get_logic, get_role, JSONLMessageLog, list_logic, list_roles, load_workflow, MemoryMessageLog, MemorySaver, mermaid_to_dag, MessageLog, OllamaDriver, OpenAIAPIDriver, RDSSaver, reducer_append, reducer_merge_list, register_logic, register_role, resolve_default_driver, RestrictedState, spawn_dag, standard_node_factory].
✖ Package has no continuous integration checks.
✖ Package coverage failed
✖ R CMD check process failed with message: 'Build process failed'.
ℹ Some goodpractice linters failed.
ℹ Function names are duplicated in other packages
ℹ Examples should not use `\dontrun` unless really necessary.

ℹ Current status:
✖ Frustration is a natural part of programming :)

ℹ 'pkgcheck' version: 0.1.2.276


── git ──

• HEAD: ae11aff7
• Default branch: main
• Number of commits: 54
• First commit: 29-03-2026
• Number of authors: 1


── Package Structure ──

ℹ Package uses the following languages:
• R: 100%

ℹ Package has
• 2 authors.
• 18 vignettes.
• No internal data
• 8 imported packages.
• 54 exported functions (median 21 lines of code).
• 4 non-exported functions (median 5 lines of code).
• 2 parameters per function (median).

── Package statistics ──

                    measure  value percentile noteworthy
1                   files_R   21.0       85.3           
4           files_vignettes   36.0      100.0           
5               files_tests   28.0       98.0           
6                     loc_R 2287.0       87.6           
7             loc_vignettes 2321.0       97.7       TRUE
8                 loc_tests 1812.0       92.3           
9             num_vignettes   18.0       99.9       TRUE
12                  n_fns_r   58.0       83.2           
13         n_fns_r_exported   54.0       89.6           
14     n_fns_r_not_exported    4.0       58.7           
15         n_fns_per_file_r    2.8       63.5           
16        num_params_per_fn    2.0       26.9           
17             loc_per_fn_r   17.0       62.0           
18         loc_per_fn_r_exp   21.5       59.0           
19     loc_per_fn_r_not_exp    5.0       50.2           
20         rel_whitespace_R   19.7       89.2           
21 rel_whitespace_vignettes   31.8       98.9       TRUE
22     rel_whitespace_tests   25.6       96.1       TRUE
23      doclines_per_fn_exp   33.5       50.9           
24  doclines_per_fn_not_exp    0.0        0.0       TRUE
25     fn_call_network_size    0.0        0.0       TRUE

ℹ Package network diagram is at ['/Users/ignatiuspang/Library/Caches/R/pkgcheck/static/HydraR_pkgstatsae11aff7.html'].


── goodpractice ──

── GP HydraR ───────────────────────────────────────────────────────────────────

It is good practice to

  ✖ avoid long code lines, it is bad for readability. Also, many people
    prefer editor windows that are about 80 characters wide. Try make
    your lines shorter than 80 characters

    R/checkpointer.R:63:81
    R/checkpointer.R:100:81
    R/checkpointer.R:183:81
    R/checkpointer.R:187:81
    R/checkpointer.R:215:81
    ... and 306 more lines

  ✖ avoid sapply(), it is not type safe. It might return a vector, or a
    list, depending on the input data. Consider using vapply() instead.

    R/driver_registry.R:67:20
    R/driver_registry.R:68:17
    tests/testthat/test-hong_kong_travel.R:50:16

──────────────────────────────────────────────────────────────────────────────── 
── Other checks ──

✖ The following function name is duplicated in other packages:
  • - `list_roles` from aws.iam



── Package Versions ──

  pkgstats: 0.2.2.20
  pkgcheck: 0.1.2.276
> 

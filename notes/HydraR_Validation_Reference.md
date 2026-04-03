# HydraR Validation Reference

HydraR includes an Advanced Validation Engine that scrutinizes your YAML workflow and Mermaid graph before execution. This document lists all supported checks, errors, and warnings to help you maintain robust agentic systems.

---

## 1. Resource Linkage Checks

These checks ensure that every node in your Mermaid graph is correctly connected to its corresponding R logic or AI persona in the YAML.

### [Error] Role Not Found
- **Condition**: A node specifies `role_id=X`, but `X` is missing from the `roles:` section.
- **Message**: `Node 'Planner': Role ID 'X' not found in registry. Check your 'roles:' section.`
- **Fix**: Ensure the ID in `roles:` matches exactly what you wrote in the Mermaid label.

### [Error] Logic Not Found
- **Condition**: A node specifies `logic_id=Y`, but `Y` is missing from the `logic:` section.
- **Message**: `Node 'Validator': Logic ID 'Y' not found in registry. Check your 'logic:' section.`
- **Fix**: Define the function or code block under the matching ID in the `logic:` section of the YAML.

---

## 2. Topology Synchronization Checks

Ensures that the visual graph (Mermaid) and the execution logic (`conditional_edges`) are perfectly aligned.

### [Error] Missing Edge (Dangling Logic)
- **Condition**: YAML defines `if_true: Target`, but the Mermaid graph does not have an arrow `Source --> Target`.
- **Message**: `Node 'A': YAML defines 'if_true: Target', but no matching edge exists in the Mermaid graph.`
- **Fix**: Add the missing arrow to the `graph:` section in your Mermaid syntax.

### [Error] Extra Edge (Unmanaged Branch)
- **Condition**: The Mermaid graph shows an arrow `A --> B`, but node `A` is a conditional node in YAML and does not list `B` as a target.
- **Message**: `Node 'A': Mermaid graph has extra edges to [B] that are not handled by 'conditional_edges' in YAML.`
- **Fix**: Either add `B` to the `if_true/if_false` logic in YAML or remove the edge from Mermaid if it was unintentional.

---

## 3. R Code & Compliance Checks (G-25)

These checks ensure your R logic blocks are syntactically valid and adhere to **APAF Bioinformatics** standards.

### [Error] Syntactic Parse Error
- **Condition**: The R code in the `logic:` block has a syntax error (e.g., missing bracket, typo).
- **Message**: `Logic 'check_fn': [Syntax Error] Unexpected token '}' at line 12.`
- **Fix**: Review the R code block. Use an IDE to verify the code is valid R.

### [Warning] APAF Rule G-25 Violation
- **Condition**: An R logic block contains a `for` loop.
- **Message**: `Logic 'X': Violation of APAF Global Rule G-25 ('for' loop detected). Use purrr::map/walk instead.`
- **Fix**: Replace the iterative loop with a functional alternative like `purrr::map()`, `purrr::walk()`, or `lapply()`.

### [Warning] Missing State Reference
- **Condition**: A character-based R logic block does not reference the `state` object.
- **Message**: `Logic 'X': 'state' object is not referenced. Ensure your logic interacts with the AgentState.`
- **Fix**: Most HydraR logic should read from or write to the `state` (e.g., `state$get("key")`). Verify if this logic is actually intended to be static.

---

## 4. Static Analysis (Lintr)

If the `lintr` package is installed, HydraR will perform deep static analysis on your code blocks.

### [Warning] Lint Warning
- **Condition**: Code style violations, undefined variables, or unused parameters.
- **Message**: `Logic 'X' [Lint]: Variable 'y' was not found in scope (line 5).`
- **Fix**: Correct the variable naming or define the required variables within the logic block.

---

> [!TIP]
> **Validation occurs automatically** every time you call `spawn_dag()` or `run_workflow()`. Always resolve Errors before execution; Warnings are advisory but recommended for APAF compliance.

<!-- APAF Bioinformatics | HydraR_Validation_Reference | Approved | 2026-04-03 -->

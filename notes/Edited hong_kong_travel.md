Edited hong_kong_travel.yml
Ran command: `ls -R R/ | grep dag`
Viewed dag.R:3-802
Ran command: `grep -r "AgentLogicNode" .`
Ran command: `ls R/`
Viewed logic_node.R:1-64
Ran command: `grep -r "load_workflow" .`
Viewed registry.R:1-219
Searched for "label"
Viewed node.R:1-51
Viewed dag.R:470-485
Viewed factory.R:1-279
Ran command: `grep -r "add_conditional_edge" .`
Ran command: `grep -r "fail" R/`
Ran command: `grep -r "E(self$graph)\$label" R/`
Viewed dag.R:400-600
Ran command: `grep -n "next_queue" R/dag.R`
Ran command: `grep -r "validation_passed" .`
Ran command: `grep -r "label" R/dag.R | grep "res\$status"`

Based on the code in `vignettes/hong_kong_travel.yml` and the orchestration logic in `R/dag.R`, here is how the `Validator` node handles its decision-making process:

### 1. Internal Logic (`validate_constraints`)
The decision is made within the R code block referenced by `logic_id=validate_constraints`. It uses a 3-step process:
- **Retrieval**: It pulls the draft itinerary produced by the `Planner` from the `state` object.
- **Verification**: It uses `purrr::map_lgl` to check if each item in the `must_include` list (e.g., "Cheung Chau Island", "Spaghetti House") exists within the itinerary (case-insensitive).
- **Decision**: 
    - If **all** items are found, it returns `validation_passed = TRUE` and a status of `SUCCESS`.
    - If any are missing, it identifies the specific `missing` items and returns `validation_passed = FALSE` with the same `SUCCESS` status (but with a failure output message).

### 2. Graph Orchestration
The "decision" to loop back to the `Planner` is governed by the **Mermaid graph** definition at the top of the YAML:
```mermaid
Validator -- "fail" --> Planner
```
In `HydraR`, when a workflow is loaded via `load_workflow()`, the edges are extracted from this graph. 

### 3. Critical Implementation Detail
In the current implementation of `AgentDAG$run_iterative()`, the decision-making for labeled edges is handled as follows:
- **Success Case**: If the `Validator` succeeds (all constraints met), it has no outgoing "success" edge defined in the graph. Since it is a terminal node for the success path, the execution for that branch stops, and the DAG status becomes `completed`.
- **Failure Case**: If the `Validator` determines it has failed, it follows its outgoing edge back to the `Planner`. 

> [!IMPORTANT]
> In the declarative YAML pattern, the labels (like `"fail"`) on Mermaid edges are currently **informational** in the graph visualization but the edges themselves are followed as standard iterative transitions. To make the loop *truly* conditional based on the `validation_passed` field without looping unconditionally, the framework typically expects the logic to either:
> 1. Use the `retries` parameter (set to `3` in your YAML) to handle repeated attempts.
> 2. Be explicitly bound as a `conditional_edge` in an accompanying R script using `dag$add_conditional_edge(..., test = function(out) isTRUE(out$validation_passed))`.

In your specific `hong_kong_travel.yml` setup, the `Validator` node "decides" by providing the `validation_passed` state, while the `retries=3` parameter ensures the loop doesn't run indefinitely if the LLM fails to meet the criteria.

Edited mermaid_orchestration_cheatsheet.md
Ran command: `grep -r "validation_passed" R/`

Based on a search of the `HydraR` core engine (`R/` directory), `validation_passed` is **not a compulsory return object**. 

It is a **convention** used in the `hong_kong_travel.yml` vignette and its associated R logic, rather than a hard-coded requirement of the framework. You can name your return fields anything (e.g., `is_valid`, `check_ok`, `score`) as long as your orchestration logic is configured to look for that specific key.

### How it works in practice:
*   **Decoupled Logic**: Your `AgentLogicNode` can return any named list in the `output` field.
*   **Explicit Mapping**: If you are using `dag$add_conditional_edge()`, you must explicitly define how to interpret that output:
    ```r
    # You define what to check here
    test = function(out) isTRUE(out$your_custom_field)
    ```
*   **Declarative YAML**: In the `hong_kong_travel.yml` pattern, the `validation_passed` field is used by the logic block to communicate state, which is then typically consumed by a human-defined conditional edge in the R script that executes the YAML. 

Actually, in the **fully declarative** mode (where no R script exists and the DAG is spawned directly from YAML), the system currently treats labeled edges (like `fail`) as standard transitions unless a specific auditor or retry logic is triggered by the `status` of the result.

<!-- APAF Bioinformatics | R_is_for_Robot | Approved -->
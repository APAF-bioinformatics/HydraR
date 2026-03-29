# HydraR: The Complete Instruction Manual

## 1. Introduction

`HydraR` is a professional-grade agentic orchestration framework built
for R. It enables the design, execution, and monitoring of complex
multi-agent workflows using a Directed Acyclic Graph (DAG) architecture
that supports **iterative loops**, **parallel execution**, and
**persistent state**.

Developed at **APAF Bioinformatics**, `HydraR` addresses the need for
durable, CLI-first agentic systems that can operate reliably in
scientific and software engineering environments.

## 2. Core Architecture

The framework is built around four primary R6 classes:

1.  **`AgentDAG`**: The central orchestrator that manages nodes, edges,
    and execution flow.
2.  **`AgentNode`**: The fundamental unit of work.
    - **`AgentLLMNode`**: Interfaces with Large Language Models via
      Drivers.
    - **`AgentLogicNode`**: Executes deterministic R functions.
3.  **`AgentState`**: A structured, centrally managed container for all
    data shared between nodes.
4.  **`AgentDriver`**: A provider-agnostic interface for communicating
    with LLMs (e.g., `GeminiCLIDriver`).

------------------------------------------------------------------------

## 3. Getting Started

### Installation

``` r

# install.packages("devtools")
devtools::install_github("apaf-bioinformatics/HydraR")
```

### Your First DAG

A simple “Hello World” agent involves creating a node, adding it to a
DAG, and running it.

``` r

library(HydraR)

# 1. Define a logic node
hello_node <- AgentLogicNode$new(
  id = "HelloNode",
  logic_fn = function(state) {
    name <- state$get("user_name", "Stranger")
    list(status = "SUCCESS", output = list(greeting = paste("Hello,", name)))
  }
)

# 2. Build and compile the DAG
dag <- AgentDAG$new()
dag$add_node(hello_node)
dag$compile()

# 3. Run with initial state
result <- dag$run(initial_state = list(user_name = "Hydra User"))
print(result$state$get("greeting"))
#> [1] "Hello, Hydra User"
```

------------------------------------------------------------------------

## 4. Advanced Orchestration

### Iterative Loops

Unlike standard DAGs, `HydraR` allows for **conditional edges** that can
loop back to previous nodes. This is essential for “self-healing” or
“refinement” patterns.

``` r

dag$add_conditional_edge(
  from = "Validator",
  test = function(out) isTRUE(out$valid),
  if_true = NULL,         # End execution
  if_false = "Generator"  # Loop back to retry
)
```

### Parallel Execution

By integrating with the `furrr` package, `HydraR` can execute
independent branches of your DAG in parallel. This is particularly
powerful when combined with **Git Worktrees** to isolate file-system
modifications.

``` r

# Run the DAG with worktree isolation enabled
result <- dag$run(
  initial_state = init,
  use_worktrees = TRUE,
  repo_root = "/path/to/repo"
)
```

------------------------------------------------------------------------

## 5. State Management & Reducers

`AgentState` ensures that all agents have a consistent view of the
world. You can use **Reducers** to control how state is updated when
multiple nodes modify the same variable.

``` r

state <- AgentState$new(
  initial_data = list(logs = list()),
  reducers = list(logs = reducer_append)
)

# Any node updating 'logs' will now append to the existing list 
# instead of overwriting it.
```

------------------------------------------------------------------------

## 6. Persistence & Resilience

For long-running workflows, `HydraR` provides a **Checkpointer** system.
If an execution is interrupted, it can be resumed from the last
successful node using a unique `thread_id`.

Supported backends: - **`MemorySaver`**: In-memory storage (default). -
**`RDSSaver`**: File-based storage. - **`DuckDBSaver`**:
High-performance persistent database.

``` r

saver <- DuckDBSaver$new(db_path = "history.duckdb")
result <- dag$run(
  initial_state = init,
  checkpointer = saver,
  thread_id = "research-session-001"
)
```

------------------------------------------------------------------------

## 7. Working with LLMs

`HydraR` is driver-agnostic. You can switch between different LLM
providers simply by changing the driver assigned to an `AgentLLMNode`.

### Gemini CLI (Recommended)

``` r

driver <- GeminiCLIDriver$new()
node <- AgentLLMNode$new(
  id = "Consultant",
  driver = driver,
  role = "Expert Consultant",
  prompt_builder = function(state) {
    sprintf("Analyze this problem: %s", state$get("problem"))
  }
)
```

------------------------------------------------------------------------

## 8. Visualization

`HydraR` generates high-quality **Mermaid.js** diagrams that can be
rendered in RStudio, GitHub, or `pkgdown`.

``` r

# Generate a status-aware plot after execution
# Success = Green, Error = Red, Active Path = High density
cat(dag$plot(status = TRUE))
```

``` mermaid
graph TD
  Start["Initial Node"] --> LLM["LLM Processor"]
  LLM --> Auditor{"Valid?"}
  Auditor -- "Yes" --> End["Final Result"]
  Auditor -- "No" --> LLM
```

------------------------------------------------------------------------

## 9. Integration with `targets`

`HydraR` works seamlessly within a `targets` pipeline. Treat an entire
`AgentDAG` execution as a single cached target.

``` r

# _targets.R
list(
  tar_target(
    agent_report,
    {
      dag <- AgentDAG$new()
      # ... define nodes ...
      dag$compile()$run(initial_state = list(input = data))$state$get_all()
    },
    format = "rds"
  )
)
```

------------------------------------------------------------------------

## 10. Conclusion

`HydraR` provides the scaffolding needed to turn isolated LLM calls into
robust, stateful, and observable agentic systems. By combining R’s
analytical power with modern LLM orchestration, it empowers
bioinformatics and data science teams to build the next generation of
intelligent tools.

For more detailed examples, refer to the [Case
Studies](https://github.com/APAF-bioinformatics/HydraR/articles/articles/hong_kong_travel.md).

------------------------------------------------------------------------

# HydraR: The Complete Guide

## HydraR: The Complete Guide

### Welcome

If you’ve ever wished you could hand off a tedious, multi-step research
task to an AI assistant—but needed the results to be *reproducible*,
*auditable*, and *safe*—then HydraR is the tool you’ve been looking for.

This guide will walk you through HydraR from the ground up. We’ll start
with the fastest way to get a workflow running—a simple YAML file—and
then show you the full R API for when you need maximum control. By the
end, you’ll be comfortable building your own agentic pipelines in R.

No prior experience with AI orchestration is needed. If you can read a
flowchart, you’re ready.

------------------------------------------------------------------------

### Part 1: What Is HydraR?

#### The Problem

Imagine you’re a researcher who needs to:

1.  Pull data from a database.
2.  Ask an LLM to summarise the key findings.
3.  Have a second LLM critically review that summary.
4.  If the review fails, loop back and try again.
5.  Save a checkpoint after every step, so a network failure at step 3
    doesn’t waste the work from steps 1 and 2.

You could write a long R script with nested `tryCatch` blocks and manual
state tracking, but that approach quickly becomes unreadable, fragile,
and impossible to share with collaborators who aren’t programmers.
HydraR solves this by letting you describe your workflow as a **visual
graph**—a flowchart—and then executing it with full state management,
persistence, and error recovery built in.

#### The Core Idea

HydraR is built around three concepts:

1.  **Nodes** — Individual units of work. A node might call an LLM, run
    an R function, or route execution based on a condition.
2.  **Edges** — Connections between nodes that define the order of
    execution. Edges can be unconditional (“always go here next”) or
    conditional (“go here if the test passed, otherwise loop back”).
3.  **State** — A shared, centralized object that every node can read
    from and write to. Think of it as a clipboard that gets passed
    around the workflow.

Together, these form an **AgentDAG** (Directed Acyclic Graph—though
HydraR also supports cycles for looping).

------------------------------------------------------------------------

### Part 2: Installation & Setup

#### Installing HydraR

``` r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("apaf-bioinformatics/HydraR")
```

#### Setting Up API Keys

Most LLM drivers need an API key. The safest way to store these is in a
`.Renviron` file in your project root:

``` bash
# .Renviron  (create this file in your project root)
GOOGLE_API_KEY="your_google_api_key_here"
ANTHROPIC_API_KEY="your_anthropic_api_key_here"
OPENAI_API_KEY="your_openai_api_key_here"
```

After creating or editing `.Renviron`, restart your R session so the
variables take effect. You can verify they’re loaded:

``` r
Sys.getenv("GOOGLE_API_KEY")
# Should print your key, not ""
```

> **Important**: Add `.Renviron` to your `.gitignore` so your keys are
> never committed to version control.

------------------------------------------------------------------------

### Part 3: Your First Workflow (YAML-First)

The fastest way to build a HydraR workflow is to describe it in a **YAML
file**. You draw the flowchart, declare your logic, and let HydraR wire
everything together. No boilerplate, no constructor calls—just three
lines of R to run it.

#### A Simple Question Answerer

Let’s build a workflow that asks an LLM a question, checks the answer,
and loops back if the answer isn’t good enough. Here’s the entire
workflow in one YAML file:

``` yaml
# question_answerer.yml

graph: |
  graph TD
    Generator["Answer Generator | type=llm | role_id=answerer"]
    Validator["Quality Gate | type=logic | logic_id=check_answer"]
    Generator --> Validator
    Validator -- "retry" --> Generator

roles:
  answerer: >
    Answer the user's question concisely. Always include
    the number 42 in your final answer.

logic:
  check_answer: |
    function(state) {
      answer <- state$get("Generator")
      is_good <- grepl("42", answer)
      list(status = "success", output = list(passed = is_good))
    }

conditional_edges:
  Validator:
    test: |
      function(result) isTRUE(result$passed)
    if_true: ~          # ~ means NULL (stop — we're done)
    if_false: Generator  # loop back and try again

initial_state:
  question: "What is the meaning of life?"
```

And the R code to run it:

``` r
library(HydraR)

wf      <- load_workflow("question_answerer.yml")
dag     <- spawn_dag(wf)
results <- dag$run(initial_state = wf$initial_state, max_steps = 10)

cat("Final answer:", results$state$get("Generator"))
```

That’s it. **Four lines of R** to execute an iterative, self-correcting
loop. The YAML file is the single source of truth—you can
version-control it, diff it in pull requests, and discuss it with
collaborators who don’t know R.

#### Anatomy of the YAML File

Every workflow file supports these top-level keys:

| Key                 | Purpose                                                                                          |
|:--------------------|:-------------------------------------------------------------------------------------------------|
| `graph`             | A Mermaid string (`graph TD` or `graph LR`) defining the topology. This is the visual blueprint. |
| `roles`             | Named system prompts for LLM nodes, referenced by `role_id`.                                     |
| `logic`             | Named R functions (inline code or file paths to `.R` files), referenced by `logic_id`.           |
| `conditional_edges` | Branching logic: `test`, `if_true`, `if_false` per node.                                         |
| `error_edges`       | Failover routing when a node returns a `failed` status.                                          |
| `start_node`        | Explicit entry point (optional; defaults to root nodes).                                         |
| `initial_state`     | Seed data injected into the `AgentState` before execution.                                       |

#### The Load → Spawn → Run Lifecycle

``` r
library(HydraR)

# 1. Load — parses YAML, registers all roles and logic automatically
wf <- load_workflow("question_answerer.yml")

# 2. Spawn — builds the DAG, wires edges, compiles, validates
dag <- spawn_dag(wf)

# 3. Run — executes the workflow with the declared initial state
results <- dag$run(initial_state = wf$initial_state)
```

Three functions. That’s the entire “Low Code” lifecycle: **Load → Spawn
→ Run**.

#### Adding Persistence to YAML

In production, you rarely want to lose your workflow state if R crashes.
You can add persistence to your YAML workflow by passing a
`checkpointer` and a `message_log` to the `run()` method:

``` r
library(HydraR)

# 1. Setup persistent storage
saver <- DuckDBSaver$new(db_path = "workflows.duckdb")
log   <- DuckDBMessageLog$new(db_path = "audit_log.duckdb")

# 2. Load and Run
wf      <- load_workflow("question_answerer.yml")
dag     <- spawn_dag(wf)
results <- dag$run(
  initial_state = wf$initial_state,
  checkpointer  = Checkpointer$new(saver = saver),
  message_log   = log
)
```

Now, every step, message, and state transition is safely stored in
DuckDB. If the pipeline fails halfway, you can resume exactly where you
left off.

#### Trust but Verify: Validation and Visualization

Before running a complex workflow, you should validate its structure and
visualize the graph to ensure it matches your expectations.

##### 1. Validating your Workflow

The
[`validate_workflow_file()`](https://APAF-bioinformatics.github.io/HydraR/reference/validate_workflow_file.md)
function performs a deep audit of your YAML. It checks for: - **Schema
Errors**: Missing required keys like `graph` or `logic`. - **Topological
Inconsistency**: Arrows in Mermaid that don’t have matching logic in
YAML. - **R Logic Linting**: Syntax errors in your inline R functions or
missing `state` references.

``` r
library(HydraR)

# Comprehensive check: schema + topology + R linting
validate_workflow_file("question_answerer.yml")
```

##### 2. Visualizing the Architecture

You can render your workflow as an interactive diagram or export it to a
high-resolution image for reports using
[`render_workflow_file()`](https://APAF-bioinformatics.github.io/HydraR/reference/render_workflow_file.md).

``` r
library(HydraR)

# View interactive diagram in RStudio
render_workflow_file("question_answerer.yml")

# Export to a high-resolution PNG for a paper or report
render_workflow_file(
  file_path   = "question_answerer.yml",
  output_file = "figures/workflow_v1.png"
)
```

#### Scaling Up: Why YAML Matters

The advantage grows with complexity. Consider a realistic 8-node
workflow with three LLM agents, two validation gates, a router, and a
merge harmoniser. In code-first style, you’d be looking at 150+ lines of
R with deeply nested constructor calls. In YAML, the Mermaid graph is
still a readable 10-line flowchart, and each component is clearly
separated under its own heading.

------------------------------------------------------------------------

### Part 4: Your First Workflow (Code-First)

The YAML approach is the recommended starting point, but HydraR also
gives you full programmatic control. The code-first API is useful when
you need dynamic graph construction, runtime logic that can’t be
expressed declaratively, or deep integration with existing R packages.

Let’s start with the simplest possible HydraR program: a single logic
node that transforms some input.

#### Step 1: Define Your Logic

Every logic function in HydraR follows the same contract: it receives an
`AgentState` object and returns a list with `status` and `output`.

``` r
library(HydraR)

# A function that greets a user by name
greeter <- function(state) {
  name <- state$get("user_name")
  greeting <- paste("Hello,", name, "— welcome to HydraR!")
  list(status = "success", output = greeting)
}
```

#### Step 2: Build the Graph

Now we wrap that function in a node, add it to a DAG, and run it:

``` r
# Create the DAG (the workflow container)
dag <- AgentDAG$new()

# Create a node from our function
dag$add_node(AgentLogicNode$new(id = "greeter", logic_fn = greeter))

# Compile — this validates the graph structure
dag$compile()

# Run with initial state
results <- dag$run(initial_state = list(user_name = "Alice"))

# Read the output
print(results$results$greeter$output)
# [1] "Hello, Alice — welcome to HydraR!"
```

That’s it. You’ve built and executed your first code-first workflow.
It’s simple on purpose—everything from here builds on these same
primitives.

------------------------------------------------------------------------

### Part 5: Chaining Nodes Together

A single node isn’t very exciting. The power of HydraR comes from
**connecting** nodes. Let’s build a two-step pipeline: one node fetches
data, and the next summarises it.

``` r
library(HydraR)

# Step 1: Fetch data
fetch_data <- function(state) {
  # Simulate pulling data from a source
  raw <- data.frame(
    gene = c("TP53", "BRCA1", "EGFR"),
    expression = c(12.4, 8.7, 15.1)
  )
  list(status = "success", output = raw)
}

# Step 2: Summarise the data
summarise_data <- function(state) {
  # Read the output from the previous node
  data <- state$get("fetcher")
  top_gene <- data[which.max(data$expression), "gene"]
  summary_text <- sprintf(
    "Analysed %d genes. Highest expression: %s (%.1f)",
    nrow(data), top_gene, max(data$expression)
  )
  list(status = "success", output = summary_text)
}

# Build the DAG
dag <- AgentDAG$new()
dag$add_node(AgentLogicNode$new(id = "fetcher", logic_fn = fetch_data))
dag$add_node(AgentLogicNode$new(id = "summariser", logic_fn = summarise_data))

# Connect them: fetcher runs first, then summariser
dag$add_edge("fetcher", "summariser")

# Compile and run
dag$compile()
results <- dag$run(initial_state = list())

print(results$results$summariser$output)
# [1] "Analysed 3 genes. Highest expression: EGFR (15.1)"
```

**How state flows**: When `fetcher` returns its output, HydraR
automatically stores it in the `AgentState` under the key `"fetcher"`.
The next node, `summariser`, can then retrieve it with
`state$get("fetcher")`. This is the fundamental mechanism—every node’s
output is stored under its ID.

------------------------------------------------------------------------

### Part 6: Adding an LLM Into the Mix

So far we’ve used pure R logic. Now let’s bring in an AI model. HydraR
uses **drivers** to communicate with LLMs. Each driver knows how to talk
to a specific provider.

#### Available Drivers

| Driver               | Provider         | Type | Requires               |
|:---------------------|:-----------------|:-----|:-----------------------|
| `GeminiAPIDriver`    | Google Gemini    | API  | `GOOGLE_API_KEY`       |
| `GeminiCLIDriver`    | Google Gemini    | CLI  | `gemini` CLI installed |
| `AnthropicAPIDriver` | Anthropic Claude | API  | `ANTHROPIC_API_KEY`    |
| `AnthropicCLIDriver` | Anthropic Claude | CLI  | `claude` CLI installed |
| `OpenAIAPIDriver`    | OpenAI GPT       | API  | `OPENAI_API_KEY`       |
| `OllamaDriver`       | Ollama (local)   | API  | Ollama running locally |

#### Example: An LLM Summariser

``` r
library(HydraR)

# Create a driver (this one talks to Google's Gemini API)
# Use Sys.getenv to securely load your API key from .Renviron
driver <- GeminiAPIDriver$new(api_key = Sys.getenv("GOOGLE_API_KEY"))

# Create the DAG
dag <- AgentDAG$new()

# A logic node that prepares data
dag$add_node(AgentLogicNode$new(
  id = "data_prep",
  logic_fn = function(state) {
    list(status = "success", output = "Gene TP53: upregulated 2.3x in tumour samples.")
  }
))

# An LLM node that interprets the data
dag$add_node(AgentLLMNode$new(
  id = "interpreter",
  role = "You are a molecular biologist. Explain findings for a general audience.",
  driver = driver,
  prompt_builder = function(state) {
    paste("Please explain this finding:", state$get("data_prep"))
  }
))

# Connect them
dag$add_edge("data_prep", "interpreter")
dag$compile()

results <- dag$run(initial_state = list())
cat(results$results$interpreter$output)
```

The `role` parameter sets the LLM’s system prompt—its identity. The
`prompt_builder` is a function that constructs the user message from the
current state. This separation means you can reuse the same role across
many different prompt contexts.

------------------------------------------------------------------------

### Part 7: Loops and Conditional Edges

This is where HydraR really shines. Many real-world tasks need
iteration: “Keep trying until the output is good enough.” HydraR handles
this with **conditional edges**.

#### The Pattern: Generate → Validate → Loop or Continue

``` r
library(HydraR)

# A mock driver for testing (no API key needed)
MockDriver <- R6::R6Class("MockDriver",
  inherit = AgentDriver,
  public = list(
    call_count = 0,
    initialize = function(id = "mock") { super$initialize(id) },
    call = function(prompt, ...) {
      self$call_count <- self$call_count + 1
      if (self$call_count >= 2) {
        return("The answer is 42.")
      }
      return("I'm not sure yet.")
    }
  )
)

driver <- MockDriver$new()
dag <- AgentDAG$new()

# Node 1: The LLM generates an answer
dag$add_node(AgentLLMNode$new(
  id = "Generator",
  role = "Answer the user's question concisely.",
  driver = driver,
  prompt_builder = function(state) state$get("question")
))

# Node 2: A validator checks the answer
dag$add_node(AgentLogicNode$new(
  id = "Validator",
  logic_fn = function(state) {
    answer <- state$get("Generator")
    is_good <- grepl("42", answer)
    list(status = "success", output = list(passed = is_good))
  }
))

# Connect: Generator → Validator
dag$set_start_node("Generator")
dag$add_edge("Generator", "Validator")

# Add the loop: if validation fails, go back to Generator
dag$add_conditional_edge(
  from = "Validator",
  test = function(result) isTRUE(result$passed),
  if_true = NULL,       # NULL means "stop — we're done"
  if_false = "Generator" # loop back
)

dag$compile()
results <- dag$run(
  initial_state = list(question = "What is the meaning of life?"),
  max_steps = 10
)

cat("Final answer:", results$state$get("Generator"))
# Final answer: The answer is 42.
cat("\nLLM was called", driver$call_count, "times")
# LLM was called 2 times
```

**Key takeaway**: The `test` function inspects the *output* of the
`from` node. If it returns `TRUE`, execution follows `if_true` (which
can be `NULL` to stop the workflow). If `FALSE`, it follows `if_false`
(which loops back in this case). The `max_steps` parameter acts as a
safety net to prevent infinite loops.

#### YAML vs Code-First: Side-by-Side Comparison

The loop above took about 40 lines of R. Compare that to the YAML
version from Part 3, which achieved the same result:

|                     | Code-First (this section)                                                                                                                                                             | YAML-First (Part 3)                          |
|:--------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------|
| **Lines of R code** | ~40                                                                                                                                                                                   | 4                                            |
| **Graph structure** | Buried in [`add_node()`](https://rich-iannone.github.io/DiagrammeR/reference/add_node.html) / [`add_edge()`](https://rich-iannone.github.io/DiagrammeR/reference/add_edge.html) calls | Visible as a Mermaid flowchart               |
| **System prompt**   | Hardcoded as a string argument                                                                                                                                                        | Named in `roles:`, reusable across workflows |
| **Logic functions** | Defined inline, tightly coupled                                                                                                                                                       | Named in `logic:`, testable in isolation     |
| **Branching logic** | Programmatic `add_conditional_edge()`                                                                                                                                                 | Declarative `conditional_edges:` block       |
| **Shareable?**      | Requires R expertise to read                                                                                                                                                          | A domain expert can read the YAML            |

**When to use which?** Start with YAML for most workflows. Switch to
code-first when you need dynamic graph construction at runtime, deep
integration with existing R objects, or patterns that can’t be expressed
declaratively.

------------------------------------------------------------------------

### Part 8: Understanding the Node Types

HydraR provides six specialised node types, each designed for a specific
role in a workflow.

#### `type=llm` — The AI Thinker

An `AgentLLMNode` sends a prompt to a Large Language Model and stores
the response. This is the node you use whenever you need creative
reasoning, natural language generation, or complex analysis.

``` r
AgentLLMNode$new(
  id = "analyst",
  role = "You are a data scientist.",
  driver = GeminiAPIDriver$new(api_key = Sys.getenv("GOOGLE_API_KEY")),
  prompt_builder = function(state) {
    paste("Analyse this dataset:", state$get("raw_data"))
  }
)
```

#### `type=logic` — The R Workhorse

An `AgentLogicNode` executes a pure R function. Use this for
deterministic tasks: data validation, file I/O, calculations, template
rendering, or decision-making.

``` r
AgentLogicNode$new(
  id = "validator",
  logic_fn = function(state) {
    data <- state$get("analyst")
    is_valid <- nchar(data) > 100
    list(status = "success", output = list(valid = is_valid))
  }
)
```

#### `type=router` — The Decision Maker

An `AgentRouterNode` dynamically chooses the *next* node based on R
logic. Unlike conditional edges (which are binary true/false), a router
can select from any number of downstream nodes.

``` r
# In YAML:
# Router["Triage | type=router | logic_id=triage_fn"]
register_logic("triage_fn", function(state) {
  priority <- state$get("priority")
  target <- if (priority == "high") "UrgentHandler" else "NormalHandler"
  list(target_node = target, output = paste("Routed to", target))
})
```

#### `type=map` — The Parallel Iterator

An `AgentMapNode` takes a list from the state and applies a function to
each item. This is HydraR’s answer to
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html) at the
workflow level.

``` r
# Process each gene in a list
# In YAML:
# Processor["Gene Analyser | type=map | map_key=gene_list | logic_id=analyse_gene"]
register_logic("analyse_gene", function(item, state) {
  list(status = "success", output = paste("Processed gene:", item))
})
```

#### `type=observer` — The Silent Watcher

An `AgentObserverNode` runs a function for its side effects (logging,
metrics, notifications) but **cannot modify the state**. It receives a
read-only view of the state, ensuring that monitoring code never
accidentally corrupts your pipeline.

``` r
# In YAML:
# Logger["Audit Log | type=observer | logic_id=log_fn"]
register_logic("log_fn", function(state) {
  message("[AUDIT] Current step reached. State keys: ", 
          paste(names(state$get_all()), collapse = ", "))
})
```

#### `type=merge` — The Reconciler

A `MergeHarmonizer` synchronises parallel execution paths. When multiple
agents work in isolated git worktrees (see Part 11), the merge node
reconciles their file changes back into the main branch.

``` r
harmonizer <- create_merge_harmonizer(id = "merge_point")
```

------------------------------------------------------------------------

### Part 9: State Management In Depth

The `AgentState` is the backbone of every HydraR workflow. Understanding
how it works will save you from confusion later.

#### How Data Flows

1.  You provide `initial_state` when calling `dag$run()`.
2.  Each node receives the full state and can read any key with
    `state$get("key")`.
3.  When a node returns `list(status = "success", output = ...)`, HydraR
    stores the `output` under the node’s ID:
    `state$set("node_id", output)`.
4.  The next node can then read it with `state$get("node_id")`.

#### Schemas: Type Safety

You can enforce types on state keys to catch errors early:

``` r
state <- AgentState$new(
  initial_data = list(count = 0, labels = list()),
  schema = list(count = "numeric", labels = "list")
)

# This would raise an error because "hello" is not numeric:
# state$set("count", "hello")
```

#### Reducers: Smart Merging

By default, `state$set("key", value)` overwrites the previous value. But
sometimes you want to *accumulate* values—for example, building a log of
all messages. **Reducers** let you define custom merge behaviour:

``` r
state <- AgentState$new(
  initial_data = list(log = list()),
  reducers = list(log = reducer_append)
)

state$update(list(log = "First entry"))
state$update(list(log = "Second entry"))
print(state$get("log"))
# [[1]] "First entry"
# [[2]] "Second entry"
```

HydraR ships with two built-in reducers: - `reducer_append` — Adds new
values to a list. - `reducer_merge_list` — Deep-merges named lists
(useful for accumulating structured results).

------------------------------------------------------------------------

### Part 10: Checkpointing and Fault Tolerance

Long-running workflows are vulnerable to interruptions: network
failures, API rate limits, or even your laptop going to sleep. HydraR’s
**checkpointing** system protects against all of these by automatically
saving the state after every node execution.

#### Using a DuckDB Checkpointer

``` r
library(HydraR)

# Create a persistent checkpointer
saver <- DuckDBSaver$new(db_path = "my_workflow_state.duckdb")

# Give your session a unique thread ID
thread_id <- "experiment-alpha-001"

# First run: suppose this fails at step 3 of 5
results <- dag$run(
  initial_state = list(input = "raw data"),
  checkpointer = saver,
  thread_id = thread_id,
  max_steps = 25
)

# Later (even in a new R session), resume from where you left off:
results <- dag$run(
  checkpointer = saver,
  thread_id = thread_id,
  resume_from = "step3"
)
```

#### Available Checkpointers

| Checkpointer  | Storage         | Best For                          |
|:--------------|:----------------|:----------------------------------|
| `MemorySaver` | RAM             | Testing and short sessions        |
| `RDSSaver`    | `.rds` files    | Simple file-based persistence     |
| `DuckDBSaver` | DuckDB database | Production workflows and auditing |

------------------------------------------------------------------------

### Part 11: Isolation with Git Worktrees

Some agents modify files on disk—generating reports, writing code, or
saving plots. When multiple agents work in parallel, they could
overwrite each other’s files. HydraR solves this with **Git worktrees**:
each parallel branch gets its own isolated copy of the repository.

#### How It Works

1.  When `use_worktrees = TRUE` is passed to `dag$run()`, HydraR creates
    a temporary Git branch and worktree for each parallel path.
2.  Each agent works in its own sandbox—it can create, modify, and
    delete files freely.
3.  When all parallel agents finish, a `MergeHarmonizer` node merges
    their changes back into the main branch.
4.  If there’s a conflict (two agents modified the same file), the DAG
    pauses with `status = "paused"`, allowing a human to resolve it.

#### Example

``` r
dag$run(
  initial_state = list(),
  use_worktrees = TRUE,
  repo_root = "/path/to/my/project",
  fail_if_dirty = TRUE  # Refuse to start if there are uncommitted changes
)
```

------------------------------------------------------------------------

### Part 12: Error Handling and Resilience

AI models are non-deterministic. They can hallucinate, time out, or
return malformed responses. HydraR provides three layers of defence.

#### Layer 1: Retries

Every node supports automatic retries. If an LLM call fails, HydraR will
try again before giving up:

``` yaml
# In a Mermaid label:
Analyst["Research Agent | type=llm | retries=3 | timeout=60"]
```

#### Layer 2: Error Edges

When a node fails even after retries, HydraR can route to a **fallback**
node instead of crashing the entire workflow. Error edges are defined
using the `"error"` label in Mermaid:

    graph TD
      A["GPT-4 Reasoning | type=llm"] -- "error" --> B["GPT-3.5 Fallback | type=llm"]

This pattern is called **model tiering**: try the expensive,
high-quality model first, but fall back to a cheaper, faster one if it
fails.

#### Layer 3: Human-in-the-Loop

For critical decisions, you can design a node that returns
`status = "pause"`. This halts the entire DAG, allowing a human to
inspect the state, make corrections, and resume:

When the DAG pauses, `dag$run()` returns with `status = "paused"` and
`paused_at = "human_review"`.

##### Human-in-the-Loop with Persistence

Resuming a complex workflow is much safer when backed by a persistent
database. This ensures that the state is preserved even if you close
your R session while waiting for human review.

``` r
library(HydraR)

# 1. Setup persistent storage
saver <- DuckDBSaver$new(db_path = "production_states.duckdb")
dag   <- dag_create(message_log = DuckDBMessageLog$new(db_path = "production_audit.duckdb"))
dag$checkpointer <- Checkpointer$new(saver = saver)

# ... add nodes as usual ...

# 2. Run until it hits a pause or error
results <- dag$run(initial_state = list(data = "raw_input"))

if (results$status == "paused") {
  cat("Workflow paused at:", results$paused_at, "\n")
  cat("State saved to DuckDB. You can now close R and come back later.\n")
}

# 3. Later (maybe in a new R session):
# The checkpointer handles seeking the last successful state in the DB
final_results <- dag$run(resume_from = results$paused_at)
```

By combining Layer 3 with DuckDB, you create a “stateful” application
that can survive restarts and human delays without losing a single bit
of progress.

------------------------------------------------------------------------

### Part 13: The Registry System

As workflows grow, you’ll want to reuse logic functions and roles across
multiple DAGs. HydraR’s **registry** is a centralised store for these
reusable components.

#### Registering Logic

``` r
# Register a reusable validation function
register_logic("check_quality", function(state) {
  score <- state$get("quality_score")
  list(status = "success", output = list(passed = score > 0.8))
})

# Later, retrieve it by name
fn <- get_logic("check_quality")

# Or reference it in a YAML workflow
# Validator["QA Gate | type=logic | logic_id=check_quality"]
```

#### Registering Roles

``` r
# Register a reusable system prompt
register_role("statistician", 
  "You are an expert biostatistician. Always cite p-values and confidence intervals."
)

# Reference it in a YAML workflow
# Analyst["Stats Agent | type=llm | role_id=statistician"]
```

#### Why Use the Registry?

- **Separation of concerns**: Your YAML file describes *what* happens;
  the registry provides *how*.
- **Testability**: You can unit-test individual logic functions in
  isolation.
- **Reusability**: The same `check_quality` function can be used in ten
  different workflows.

------------------------------------------------------------------------

### Part 14: Visualising Your Workflow

HydraR can export any graph to Mermaid.js syntax, which can be rendered
in Markdown files, Jupyter notebooks, GitHub READMEs, or the
`DiagrammeR` package in R.

#### Rendering a DAG

``` r
library(HydraR)
library(DiagrammeR)

# After building your DAG:
mermaid_code <- dag$plot()
DiagrammeR::mermaid(mermaid_code)
```

#### Post-Execution Status Visualisation

After a run completes, you can generate a coloured diagram showing which
nodes succeeded, failed, or were skipped:

``` r
# Green = success, Red = failed, Grey = skipped
DiagrammeR::mermaid(dag$plot(status = TRUE))
```

This is invaluable for debugging long workflows—you can immediately see
where things went wrong.

------------------------------------------------------------------------

### Part 15: Model Context Protocol (MCP)

HydraR supports the **Model Context Protocol (MCP)**, which allows LLM
agents to interact with external tools like databases, file systems, and
APIs.

#### How It Works

HydraR doesn’t act as an MCP client itself. Instead, it orchestrates
agents whose underlying CLI tools (like `claude` or `gemini`) natively
support MCP. You configure MCP through the `cli_opts` parameter:

``` r
# Claude with MCP SQL server
node <- AgentLLMNode$new(
  id = "db_analyst",
  role = "Query the database and summarise the results.",
  driver = AnthropicCLIDriver$new(),
  cli_opts = list(
    mcp_config = "/path/to/mcp_config.json"
  )
)
```

``` yaml
# Or in YAML:
graph: |
  graph TD
    DBAgent["SQL Analyst | type=llm | driver=anthropic | role_id=sql_role"]
logic:
  DBAgent:
    cli_opts:
      mcp_config: "/etc/hydrar/mcp/sql_config.json"
```

------------------------------------------------------------------------

### Part 16: Putting It All Together

Here’s a complete, realistic example that combines everything we’ve
learned. This workflow analyses gene expression data using an iterative
refinement loop with checkpointing.

``` r
library(HydraR)

# ── 1. Register reusable logic ──
register_logic("parse_results", function(state) {
  raw <- state$get("LLMAnalyst")
  has_stats <- grepl("p-value|confidence", raw, ignore.case = TRUE)
  list(status = "success", output = list(quality_ok = has_stats))
})

register_role("gene_analyst",
  "You are a bioinformatics researcher. When analysing gene expression data,
   always report fold changes, p-values, and confidence intervals."
)

# ── 2. Build the DAG ──
driver <- GeminiAPIDriver$new(api_key = Sys.getenv("GOOGLE_API_KEY"))
dag <- AgentDAG$new()

dag$add_node(AgentLogicNode$new(
  id = "DataLoader",
  logic_fn = function(state) {
    list(status = "success",
         output = "Genes: TP53 (FC=2.3, p=0.001), BRCA1 (FC=0.8, p=0.42)")
  }
))

dag$add_node(AgentLLMNode$new(
  id = "LLMAnalyst",
  role = get_role("gene_analyst"),
  driver = driver,
  prompt_builder = function(state) {
    paste("Interpret these gene expression results:\n", state$get("DataLoader"))
  }
))

dag$add_node(AgentLogicNode$new(
  id = "QualityGate",
  logic_fn = get_logic("parse_results")
))

# ── 3. Wire the edges ──
dag$set_start_node("DataLoader")
dag$add_edge("DataLoader", "LLMAnalyst")
dag$add_edge("LLMAnalyst", "QualityGate")

dag$add_conditional_edge(
  from = "QualityGate",
  test = function(out) isTRUE(out$quality_ok),
  if_true = NULL,          # Done — quality passed
  if_false = "LLMAnalyst"  # Try again
)

# ── 4. Run with checkpointing ──
saver <- DuckDBSaver$new(db_path = "gene_analysis.duckdb")

results <- dag$run(
  initial_state = list(),
  checkpointer = saver,
  thread_id = "gene-expr-001",
  max_steps = 10
)

cat("Status:", results$status, "\n")
cat("Final analysis:\n", results$state$get("LLMAnalyst"))
```

------------------------------------------------------------------------

### Quick Reference: Mermaid Label Syntax

When defining nodes in Mermaid, HydraR uses a pipe-separated format
inside the label:

    NodeID["Human Readable Name | key=value | key=value"]

#### Supported Keys

| Key         | Description                              | Example                                 |
|:------------|:-----------------------------------------|:----------------------------------------|
| `type`      | Node type                                | `type=llm`, `type=logic`, `type=router` |
| `role_id`   | Registry key for the system prompt       | `role_id=analyst`                       |
| `logic_id`  | Registry key for the R function          | `logic_id=validate_fn`                  |
| `driver`    | LLM driver shorthand                     | `driver=gemini`, `driver=anthropic`     |
| `map_key`   | State key containing the list to iterate | `map_key=gene_list`                     |
| `isolation` | Enable git worktree isolation            | `isolation=true`                        |
| `retries`   | Number of retry attempts                 | `retries=3`                             |
| `timeout`   | Timeout in seconds                       | `timeout=60`                            |

#### Edge Types

    A --> B           Regular edge (A runs before B)
    A -- "error" --> B  Error edge (B runs only if A fails)
    A -- "fail" --> B   Labelled edge (used for documentation)

------------------------------------------------------------------------

### Next Steps

Now that you understand the fundamentals, explore these resources to go
deeper:

- **[Sydney to Hong Kong Travel
  Planner](https://APAF-bioinformatics.github.io/HydraR/articles/hong_kong_travel.md)**:
  A full case study demonstrating the Zero-R-Code pattern with visual
  asset generation.
- **[Parallel Sorting
  Benchmark](https://APAF-bioinformatics.github.io/HydraR/articles/sorting_benchmark.md)**:
  How to use Git worktrees for isolated, parallel agent execution.
- **[State Persistence &
  Recovery](https://APAF-bioinformatics.github.io/HydraR/articles/state_persistence.md)**:
  Deep dive into DuckDB checkpointing for fault-tolerant pipelines.
- **[Creating Custom
  Drivers](https://APAF-bioinformatics.github.io/HydraR/articles/extending_hydrar.md)**:
  Build your own driver for a local LLM or enterprise API.
- **[Targets
  Integration](https://APAF-bioinformatics.github.io/HydraR/articles/targets_integration.md)**:
  Combine HydraR with the `targets` package for cached, reproducible
  pipelines.

------------------------------------------------------------------------

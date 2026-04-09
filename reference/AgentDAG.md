# Agent Graph R6 Class

The core orchestrator in HydraR, `AgentDAG` defines and executes a
Directed Graph of `AgentNode` objects. It supports:

- **Pure DAGs**: Parallel execution using `furrr`.

- **Cycles & Loops**: Iterative execution via conditional edges.

- **State Isolation**: Parallel branch execution in isolated git
  worktrees.

- **Persistence**: Automatic state checkpointing and restoration.

## Value

An `AgentDAG` R6 object.

## Public fields

- `nodes`:

  List. Named list of AgentNode objects.

- `edges`:

  List. Pending edge definitions to be bound.

- `conditional_edges`:

  List. Conditional transition logic.

- `error_edges`:

  List. Failover transition logic.

- `results`:

  List. Execution results for each node.

- `trace_log`:

  List. Execution telemetry and tracing.

- `graph`:

  igraph. Internal graph representation.

- `start_node`:

  String. Explicit entry point for cycles.

- `state`:

  AgentState. Centralized state object.

- `message_log`:

  MessageLog. Optional audit log.

- `worktree_manager`:

  WorktreeManager. Optional isolation manager.

## Methods

### Public methods

- [`AgentDAG$new()`](#method-AgentDAG-new)

- [`AgentDAG$set_start_node()`](#method-AgentDAG-set_start_node)

- [`AgentDAG$add_node()`](#method-AgentDAG-add_node)

- [`AgentDAG$add_edge()`](#method-AgentDAG-add_edge)

- [`AgentDAG$add_conditional_edge()`](#method-AgentDAG-add_conditional_edge)

- [`AgentDAG$add_error_edge()`](#method-AgentDAG-add_error_edge)

- [`AgentDAG$run()`](#method-AgentDAG-run)

- [`AgentDAG$.run_linear()`](#method-AgentDAG-.run_linear)

- [`AgentDAG$.run_iterative()`](#method-AgentDAG-.run_iterative)

- [`AgentDAG$plot()`](#method-AgentDAG-plot)

- [`AgentDAG$get_terminal_nodes()`](#method-AgentDAG-get_terminal_nodes)

- [`AgentDAG$get_start_nodes()`](#method-AgentDAG-get_start_nodes)

- [`AgentDAG$compile()`](#method-AgentDAG-compile)

- [`AgentDAG$save_trace()`](#method-AgentDAG-save_trace)

- [`AgentDAG$from_mermaid()`](#method-AgentDAG-from_mermaid)

- [`AgentDAG$clone()`](#method-AgentDAG-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize AgentDAG

#### Usage

    AgentDAG$new()

#### Returns

A new `AgentDAG` instance with empty node and edge lists.

------------------------------------------------------------------------

### Method `set_start_node()`

Set Start Node(s) Explicitly defines the entry point(s) of the graph. If
not called, the engine defaults to nodes with an in-degree of 0.
Required for graphs with cycles or where execution must start at a
specific node.

#### Usage

    AgentDAG$set_start_node(node_ids)

#### Arguments

- `node_ids`:

  Character vector. A vector of one or more node IDs. These nodes must
  already exist in the DAG (added via `add_node`).

#### Returns

The `AgentDAG` object (invisibly).

------------------------------------------------------------------------

### Method [`add_node()`](https://rich-iannone.github.io/DiagrammeR/reference/add_node.html)

Add a Node Registers an `AgentNode` object into the graph.

#### Usage

    AgentDAG$add_node(node)

#### Arguments

- `node`:

  AgentNode. An instance of `AgentNode` or a subclass (e.g.,
  `AgentLLMNode`). The ID of the node must be unique within the DAG.

#### Returns

The `AgentDAG` object (invisibly).

------------------------------------------------------------------------

### Method [`add_edge()`](https://rich-iannone.github.io/DiagrammeR/reference/add_edge.html)

Add an Edge Creates a directed connection between nodes. Also supports
specialized edge types (Error, Test, Fail) via labeling.

#### Usage

    AgentDAG$add_edge(from, to, label = NULL)

#### Arguments

- `from`:

  String or Character vector. The source node ID(s).

- `to`:

  String. The destination node ID.

- `label`:

  String. Optional label for the edge. In HydraR, certain labels trigger
  logic:

  - `"error"` or `"failover"`: Creates an error edge.

  - `"Test"`: Creates a conditional edge (true path).

  - `"Fail"`: Creates a conditional edge (false path).

#### Returns

The `AgentDAG` object (invisibly).

------------------------------------------------------------------------

### Method `add_conditional_edge()`

Add a Conditional Edge (Loop Support) Adds branching logic to the graph.
After the `from` node executes, the `test` function is evaluated against
the node's result.

#### Usage

    AgentDAG$add_conditional_edge(
      from,
      test = NULL,
      if_true = NULL,
      if_false = NULL
    )

#### Arguments

- `from`:

  String. The ID of the source node.

- `test`:

  Function. A predicate function that takes the node result list and
  returns `TRUE` or `FALSE`.

- `if_true`:

  String. Optional ID of the node to execute if the test passes.

- `if_false`:

  String. Optional ID of the node to execute if the test fails.

#### Returns

The `AgentDAG` object (invisibly).

------------------------------------------------------------------------

### Method `add_error_edge()`

Add an Error Edge (Failover Support)

#### Usage

    AgentDAG$add_error_edge(from, to)

#### Arguments

- `from`:

  String node ID.

- `to`:

  String node ID.

#### Returns

The AgentDAG object (invisibly).

------------------------------------------------------------------------

### Method `run()`

Run the Graph The primary execution engine for the `AgentDAG`. It
manages the orchestration lifecycle, including state initialization /
recovery, worktree setup for isolation, and routing between nodes. It
automatically switches between linear (parallel-capable) and iterative
execution modes based on the graph's complexity.

#### Usage

    AgentDAG$run(
      initial_state = NULL,
      max_steps = 25,
      checkpointer = NULL,
      thread_id = NULL,
      resume_from = NULL,
      use_worktrees = FALSE,
      repo_root = getwd(),
      cleanup_policy = "auto",
      fail_if_dirty = TRUE,
      packages = c("withr"),
      ...
    )

#### Arguments

- `initial_state`:

  List, AgentState, or String. The starting data for the workflow. Can
  be a named list of R objects, an existing `AgentState` instance, or a
  path to a checkpoint (if supported). Required unless resuming from a
  checkpointer.

- `max_steps`:

  Integer. The maximum number of node executions allowed in a single
  `run()` call. Prevents infinite loops in cyclic graphs. Default is 25.

- `checkpointer`:

  Checkpointer. An optional `Checkpointer` R6 object. If provided, the
  state is automatically saved after every node execution.

- `thread_id`:

  String. A unique identifier for this execution "thread" or session.
  Required if using a `checkpointer` to resolve the correct state from
  storage.

- `resume_from`:

  String. Optional node ID. If provided (or found in a checkpoint),
  execution will skip completed nodes and start from this point.

- `use_worktrees`:

  Logical. Enable branch isolation. If `TRUE`, parallel branches are
  executed in separate git worktrees, preventing file-system conflicts
  between agents.

- `repo_root`:

  String. Path to the master git repository. Required if `use_worktrees`
  is `TRUE`.

- `cleanup_policy`:

  String. One of `"auto"` (default), `"none"`, or `"aggressive"`.
  Determines how worktrees are removed after execution.

- `fail_if_dirty`:

  Logical. If `TRUE`, execution fails if the `repo_root` has uncommitted
  changes (recommended for reproducibility when using worktrees).

- `packages`:

  Character vector. A list of R packages to load on parallel worker
  nodes (passed to `furrr`).

- `...`:

  Additional arguments. Passed down to individual `node$run()` calls.

#### Returns

A list containing:

- `results`: A named list of each node's output.

- `state`: The final `AgentState` object.

- `status`: `"completed"` or `"paused"`.

Internal: Linear DAG Execution

------------------------------------------------------------------------

### Method `.run_linear()`

#### Usage

    AgentDAG$.run_linear(
      max_steps = 25,
      checkpointer = NULL,
      thread_id = NULL,
      resume_from = NULL,
      node_ids = NULL,
      step_count = 0,
      fail_if_dirty = TRUE
    )

#### Arguments

- `max_steps`:

  Integer.

- `checkpointer`:

  Checkpointer object.

- `thread_id`:

  String thread ID.

- `resume_from`:

  Node ID(s) to resume from.

- `node_ids`:

  Character vector of nodes to run.

- `step_count`:

  Integer current total step count.

- `fail_if_dirty`:

  Logical.

#### Returns

Execution result list. Internal: Iterative Execution

------------------------------------------------------------------------

### Method `.run_iterative()`

#### Usage

    AgentDAG$.run_iterative(
      max_steps,
      checkpointer = NULL,
      thread_id = NULL,
      resume_from = NULL,
      step_count = 0,
      fail_if_dirty = TRUE,
      packages = c("withr")
    )

#### Arguments

- `max_steps`:

  Integer.

- `checkpointer`:

  Checkpointer object.

- `thread_id`:

  String.

- `resume_from`:

  String.

- `step_count`:

  Integer.

- `fail_if_dirty`:

  Logical.

- `packages`:

  Character vector. Packages to load in parallel workers. Visualize the
  Graph

------------------------------------------------------------------------

### Method [`plot()`](https://rdrr.io/r/graphics/plot.default.html)

Generates a visual representation of the DAG using Mermaid or DOT
syntax.

#### Usage

    AgentDAG$plot(
      type = "mermaid",
      status = FALSE,
      details = FALSE,
      include_params = NULL,
      show_edge_labels = TRUE
    )

#### Arguments

- `type`:

  String. Either `"mermaid"` (default) for web-native rendering or
  `"grViz"` for DiagrammeR/Graphviz.

- `status`:

  Logical. If `TRUE`, colors nodes based on the results in the current
  trace log (Green: Success, Red: Failed, Yellow: Paused).

- `details`:

  Logical. If `TRUE`, injects node parameters into the labels.

- `include_params`:

  Character vector. Optional whitelist of parameter names to display
  when `details` is `TRUE`.

- `show_edge_labels`:

  Logical. Whether to display labels (e.g., "Test", "Fail") on edges.

#### Returns

The Mermaid/DOT source string (invisibly).

#### Examples

    \dontrun{
    dag <- dag_create()
    dag$add_node(AgentNode$new("A"))
    dag$add_node(AgentNode$new("B"))
    dag$add_edge("A", "B", label = "proceed")

    # Generate Mermaid string
    m_src <- dag$plot(type = "mermaid", show_edge_labels = TRUE)
    cat(m_src)
    }

------------------------------------------------------------------------

### Method `get_terminal_nodes()`

Get Terminal Nodes Identifies nodes with no outgoing edges.

#### Usage

    AgentDAG$get_terminal_nodes()

#### Returns

Character vector of node IDs.

------------------------------------------------------------------------

### Method `get_start_nodes()`

Get Start Nodes (Roots) Identifies nodes with no incoming edges.

#### Usage

    AgentDAG$get_start_nodes()

#### Returns

Character vector of node IDs. Compile the Graph

------------------------------------------------------------------------

### Method `compile()`

Rebuilds the internal `igraph` representation and performs validation
checks such as cycle detection, start node disambiguation, and
reachability analysis. This must be called before `run()`.

#### Usage

    AgentDAG$compile()

#### Details

Compilation will throw errors if:

- Cycles are found in a pure DAG (no conditional edges).

- Multiple root nodes are found without an explicit `start_node`.

- Node IDs used in edges do not exist.

#### Returns

The `AgentDAG` object (invisibly). Save the Execution Trace

------------------------------------------------------------------------

### Method `save_trace()`

Exports the detailed telemetry from the last execution (durations,
status, outputs) to a JSON file.

#### Usage

    AgentDAG$save_trace(file = "dag_trace.json")

#### Arguments

- `file`:

  String. Path to the output JSON file. Defaults to `"dag_trace.json"`.

#### Returns

The `AgentDAG` object (invisibly). Create Graph from Mermaid

------------------------------------------------------------------------

### Method `from_mermaid()`

A static-like method to populate a DAG from a Mermaid string using a
custom node factory.

#### Usage

    AgentDAG$from_mermaid(mermaid_str, node_factory)

#### Arguments

- `mermaid_str`:

  String. A valid Mermaid graph definition (e.g., `"graph TD; A-->B"`).

- `node_factory`:

  Function. A closure mapping Mermaid labels and parameters to
  `AgentNode` instances. See
  [`auto_node_factory`](https://github.com/APAF-bioinformatics/HydraR/reference/auto_node_factory.md)
  for the standard implementation.

#### Returns

The `AgentDAG` object (invisibly).

#### Examples

    \dontrun{
    # Use a custom factory to map all nodes to Logic nodes
    simple_factory <- function(id, label, params) {
      AgentLogicNode$new(id = id, logic_fn = function(s) list(status="ok"))
    }

    dag <- AgentDAG$new()
    dag$from_mermaid("graph LR; Start-->End", simple_factory)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AgentDAG$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Define a simple linear workflow
dag <- AgentDAG$new()

# Define a logic function
fetch_data <- function(state) {
  list(status = "success", output = list(raw = "Some data"))
}

# Add nodes
dag$add_node(AgentLogicNode$new("fetcher", logic_fn = fetch_data))
dag_add_llm_node(
  dag,
  id = "analyzer",
  role = "Analyze the data in the state.",
  driver = GeminiCLIDriver$new()
)

# Connect nodes
dag$add_edge("fetcher", "analyzer")

# Compile and verify the graph
dag$compile()

# Execution requires an initial state
results <- dag$run(initial_state = list(input_file = "raw.txt"))
} # }

## ------------------------------------------------
## Method `AgentDAG$plot`
## ------------------------------------------------

if (FALSE) { # \dontrun{
dag <- dag_create()
dag$add_node(AgentNode$new("A"))
dag$add_node(AgentNode$new("B"))
dag$add_edge("A", "B", label = "proceed")

# Generate Mermaid string
m_src <- dag$plot(type = "mermaid", show_edge_labels = TRUE)
cat(m_src)
} # }

## ------------------------------------------------
## Method `AgentDAG$from_mermaid`
## ------------------------------------------------

if (FALSE) { # \dontrun{
# Use a custom factory to map all nodes to Logic nodes
simple_factory <- function(id, label, params) {
  AgentLogicNode$new(id = id, logic_fn = function(s) list(status="ok"))
}

dag <- AgentDAG$new()
dag$from_mermaid("graph LR; Start-->End", simple_factory)
} # }
```

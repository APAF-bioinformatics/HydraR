# Agent Graph R6 Class

Defines and executes a Directed Graph of AgentNodes. Supports both pure
DAG execution (parallel) and iterative loops via conditional edges.

## Value

An \`AgentDAG\` R6 object.

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

Initialize AgentDAG Set Start Node(s)

#### Usage

    AgentDAG$new()

------------------------------------------------------------------------

### Method `set_start_node()`

#### Usage

    AgentDAG$set_start_node(node_ids)

#### Arguments

- `node_ids`:

  Character vector of node IDs.

#### Returns

The AgentDAG object (invisibly). Add a Node

------------------------------------------------------------------------

### Method [`add_node()`](https://rich-iannone.github.io/DiagrammeR/reference/add_node.html)

#### Usage

    AgentDAG$add_node(node)

#### Arguments

- `node`:

  AgentNode object.

#### Returns

The AgentDAG object (invisibly). Add an Edge

------------------------------------------------------------------------

### Method [`add_edge()`](https://rich-iannone.github.io/DiagrammeR/reference/add_edge.html)

#### Usage

    AgentDAG$add_edge(from, to, label = NULL)

#### Arguments

- `from`:

  String or character vector of node IDs.

- `to`:

  String node ID.

- `label`:

  Optional string label for the edge.

#### Returns

The AgentDAG object (invisibly). Add a Conditional Edge (Loop Support)

------------------------------------------------------------------------

### Method `add_conditional_edge()`

#### Usage

    AgentDAG$add_conditional_edge(
      from,
      test = NULL,
      if_true = NULL,
      if_false = NULL
    )

#### Arguments

- `from`:

  String node ID.

- `test`:

  Function(output) -\> Logical.

- `if_true`:

  String node ID (next node if test is TRUE) or NULL.

- `if_false`:

  String node ID (next node if test is FALSE) or NULL. Add an Error Edge
  (Failover Support)

------------------------------------------------------------------------

### Method `add_error_edge()`

#### Usage

    AgentDAG$add_error_edge(from, to)

#### Arguments

- `from`:

  String node ID.

- `to`:

  String node ID.

#### Returns

The AgentDAG object (invisibly). Run the Graph

------------------------------------------------------------------------

### Method `run()`

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

  List, AgentState object, or String. Optional if resuming.

- `max_steps`:

  Integer. Maximum iterations to prevent infinite loops. Default is 25.

- `checkpointer`:

  Checkpointer object. Optional.

- `thread_id`:

  String. Identifier for the execution thread. Required if using
  checkpointer.

- `resume_from`:

  String. Node ID to resume execution from.

- `use_worktrees`:

  Logical. Whether to use isolated git worktrees for parallel branches.

- `repo_root`:

  String. Path to the main git repository.

- `cleanup_policy`:

  String. "auto", "none", or "aggressive".

- `fail_if_dirty`:

  Logical. Whether to fail if repo has uncommitted changes.

- `packages`:

  Character vector. Packages to load in parallel workers.

- `...`:

  Additional arguments passed to node run methods.

#### Returns

List of results for each node, and the final state. Internal: Linear DAG
Execution

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

  Character vector. Packages to load in parallel workers.

------------------------------------------------------------------------

### Method [`plot()`](https://rdrr.io/r/graphics/plot.default.html)

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

  String. Type of plot ("mermaid" or "grViz").

- `status`:

  Logical. If TRUE, styling is applied to nodes/edges based on results.

- `details`:

  Logical. If TRUE, node parameters are serialized into labels.

- `include_params`:

  Character vector. Optional whitelist of parameters to show.

- `show_edge_labels`:

  Logical. Whether to show labels on edges.

#### Returns

The mermaid/dot string (invisibly). Get Terminal Nodes

------------------------------------------------------------------------

### Method `get_terminal_nodes()`

Identifies nodes with no outgoing edges.

#### Usage

    AgentDAG$get_terminal_nodes()

#### Returns

Character vector of node IDs. Get Start Nodes (Roots)

------------------------------------------------------------------------

### Method `get_start_nodes()`

Identifies nodes with no incoming edges.

#### Usage

    AgentDAG$get_start_nodes()

#### Returns

Character vector of node IDs. Compile the Graph

------------------------------------------------------------------------

### Method `compile()`

Rebuilds the internal graph representation and performs validation
checks.

#### Usage

    AgentDAG$compile()

#### Returns

The AgentDAG object (invisibly). Save the Execution Trace

------------------------------------------------------------------------

### Method `save_trace()`

#### Usage

    AgentDAG$save_trace(file = "dag_trace.json")

#### Arguments

- `file`:

  String. Output path for the JSON trace. Create Graph from Mermaid

------------------------------------------------------------------------

### Method `from_mermaid()`

#### Usage

    AgentDAG$from_mermaid(mermaid_str, node_factory)

#### Arguments

- `mermaid_str`:

  String. Mermaid syntax.

- `node_factory`:

  Function(id, label, params) -\> AgentNode.

#### Returns

The AgentDAG object.

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
dag <- AgentDAG$new()
node <- AgentLogicNode$new("start", function(state) list(status = "success"))
dag$add_node(node)
if (FALSE) { # \dontrun{
dag <- AgentDAG$new()
dag$add_node(AgentNode$new("A"))
dag$add_node(AgentNode$new("B"))
dag$add_edge("A", "B")
dag$set_start_node("A")
dag$compile()
} # }
```

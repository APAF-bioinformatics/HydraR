# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        dag.R
# Author:      APAF Agentic Workflow
# Purpose:     Multi-Agent Graph Orchestrator (DAG + Loops)
# Constraint:  Hardness-Oriented Development, Parallel Execution (furrr)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Graph R6 Class
#'
#' @description
#' The core orchestrator in HydraR, \code{AgentDAG} defines and executes a
#' Directed Graph of \code{AgentNode} objects. It supports:
#' \itemize{
#'   \item \strong{Pure DAGs}: Parallel execution using \code{furrr}.
#'   \item \strong{Cycles & Loops}: Iterative execution via conditional edges.
#'   \item \strong{State Isolation}: Parallel branch execution in isolated git worktrees.
#'   \item \strong{Persistence}: Automatic state checkpointing and restoration.
#' }
#'
#' @return An \code{AgentDAG} R6 object.
#'
#' @examples
#' \dontrun{
#' # 1. Define a complex DAG with branching, loops, and custom state
#' # Initializing the orchestrator
#' dag <- AgentDAG$new()
#'
#' # Define logic for data retrieval and quality control
#' register_logic("fetcher", function(state) list(status = "success", output = "raw data"))
#' register_logic("gate", function(state) {
#'   if (nchar(state$get("fetcher")) > 5) list(status = "true") else list(status = "false")
#' })
#'
#' # 2. Programmatic Node Construction
#' dag$add_node(AgentLogicNode$new("start", logic_fn = get_logic("fetcher")))
#' dag$add_node(AgentLogicNode$new("check", logic_fn = get_logic("gate")))
#'
#' # 3. Connecting nodes with status-based edges
#' # Errors in 'start' go to a terminal cleanup node
#' dag$add_edge("start", "check")
#' dag$add_conditional_edge("check",
#'   test = function(res) res$status == "true",
#'   if_true = "process", if_false = "retry"
#' )
#'
#' # 4. Multi-agent execution context
#' # Compiling and running with initial state
#' dag$compile()
#' final_state <- dag$run(initial_state = list(job_id = "123"))
#'
#' # Checking results
#' print(final_state$get_all())
#' }
#' @importFrom R6 R6Class
#' @importFrom digest digest
#' @importFrom jsonlite toJSON fromJSON write_json
#' @importFrom igraph graph_from_data_frame is_dag topo_sort edge V vcount make_empty_graph degree is_connected components bfs
#' @importFrom furrr future_map
#' @importFrom purrr map set_names iwalk walk
#' @export
AgentDAG <- R6::R6Class("AgentDAG",
  public = list(
    #' @field nodes List. Named list of AgentNode objects.
    nodes = list(),
    #' @field edges List. Pending edge definitions to be bound.
    edges = list(),
    #' @field conditional_edges List. Conditional transition logic.
    conditional_edges = list(),
    #' @field error_edges List. Failover transition logic.
    error_edges = list(),
    #' @field results List. Execution results for each node.
    results = list(),
    #' @field trace_log List. Execution telemetry and tracing.
    trace_log = list(),
    #' @field graph igraph. Internal graph representation.
    graph = NULL,
    #' @field start_node String. Explicit entry point for cycles.
    start_node = NULL,
    #' @field state AgentState. Centralized state object.
    state = NULL,
    #' @field message_log MessageLog. Optional audit log.
    message_log = NULL,
    #' @field worktree_manager WorktreeManager. Optional isolation manager.
    worktree_manager = NULL,

    #' @description Initialize AgentDAG
    #' @return A new \code{AgentDAG} instance with empty node and edge lists.
    initialize = function() {
      self$nodes <- list()
      self$edges <- list()
      self$conditional_edges <- list()
      self$error_edges <- list()
      self$results <- list()
      self$trace_log <- list()
      self$graph <- NULL
      self$start_node <- NULL
      self$state <- NULL
      self$message_log <- NULL
      self$worktree_manager <- NULL
    },

    #' @description Set Start Node(s)
    #' Explicitly defines the entry point(s) of the graph. If not called, the
    #' engine defaults to nodes with an in-degree of 0. Required for graphs
    #' with cycles or where execution must start at a specific node.
    #'
    #' @param node_ids Character vector.
    #' A vector of one or more node IDs. These nodes must already exist in the
    #' DAG (added via \code{add_node}).
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    set_start_node = function(node_ids) {
      if (!is.character(node_ids) || length(node_ids) < 1) {
        stop("node_ids must be a character vector of node IDs.")
      }
      missing_nodes <- setdiff(node_ids, names(self$nodes))
      if (length(missing_nodes) > 0) {
        stop(sprintf("Node(s) '%s' not found in DAG. Add the nodes before setting them as start.", paste(missing_nodes, collapse = ", ")))
      }
      self$start_node <- node_ids
      invisible(self)
    },

    #' @description Add a Node
    #' Registers an \code{AgentNode} object into the graph.
    #'
    #' @param node AgentNode.
    #' An instance of \code{AgentNode} or a subclass (e.g., \code{AgentLLMNode}).
    #' The ID of the node must be unique within the DAG.
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    add_node = function(node) {
      if (!inherits(node, "AgentNode")) {
        stop(sprintf("node must be an AgentNode object (received: %s).", class(node)[1]))
      }
      if (node$id %in% names(self$nodes)) {
        stop(sprintf("Node ID '%s' already exists in DAG.", node$id))
      }
      self$nodes[[node$id]] <- node
      invisible(self)
    },

    #' @description Add an Edge
    #' Creates a directed connection between nodes. Also supports specialized
    #' edge types (Error, Test, Fail) via labeling.
    #'
    #' @param from String or Character vector.
    #' The source node ID(s).
    #' @param to String.
    #' The destination node ID.
    #' @param label String.
    #' Optional label for the edge. In HydraR, certain labels trigger logic:
    #' \itemize{
    #'   \item \code{"error"} or \code{"failover"}: Creates an error edge.
    #'   \item \code{"Test"}: Creates a conditional edge (true path).
    #'   \item \code{"Fail"}: Creates a conditional edge (false path).
    #' }
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    add_edge = function(from, to, label = NULL) {
      if (!is.character(from)) stop("from must be a character vector of node IDs.")
      if (!is.character(to) || length(to) != 1) stop("to must be a single string node ID.")

      l_clean <- if (!is.null(label)) trimws(label) else NULL

      # 1. SPECIALIZED: Error / Failover
      if (!is.null(l_clean) && tolower(l_clean) %in% c("error", "failover")) {
        purrr::walk(from, ~ self$add_error_edge(.x, to))
        return(invisible(self))
      }

      # 2. SPECIALIZED: Conditional Test/Fail
      if (!is.null(l_clean) && (l_clean %in% c("Test", "Fail") || grepl("^test:", l_clean))) {
        # Default test: status == "success"
        test_fn <- function(v) isTRUE(v$status == "success")

        # If test: prefix is used, resolve it
        if (grepl("^test:", l_clean)) {
          test_id <- gsub("^test:", "", l_clean)
          # We use a lazy resolver since we are during build/parsing
          # resolve_test_pattern is in registry.R
          test_fn <- function(v) {
            resolve_test_pattern(test_id)(v)
          }
        }

        purrr::walk(from, function(f) {
          if (l_clean == "Fail") {
            self$add_conditional_edge(f, test = test_fn, if_false = to)
          } else {
            # Default or "Test" or "test:..." goes to if_true
            self$add_conditional_edge(f, test = test_fn, if_true = to)
          }
        })
        return(invisible(self))
      }

      new_edges <- data.frame(
        from = from,
        to = to,
        label = label %||% NA_character_,
        stringsAsFactors = FALSE
      )
      self$edges[[length(self$edges) + 1]] <- new_edges
      self$graph <- NULL # Invalidate cache
      invisible(self)
    },

    #' @description Add a Conditional Edge (Loop Support)
    #' Adds branching logic to the graph. After the \code{from} node executes,
    #' the \code{test} function is evaluated against the node's result.
    #'
    #' @param from String.
    #' The ID of the source node.
    #' @param test Function.
    #' A predicate function that takes the node result list and returns
    #' \code{TRUE} or \code{FALSE}.
    #' @param if_true String.
    #' Optional ID of the node to execute if the test passes.
    #' @param if_false String.
    #' Optional ID of the node to execute if the test fails.
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    add_conditional_edge = function(from, test = NULL, if_true = NULL, if_false = NULL) {
      if (!is.character(from) || length(from) != 1 || !from %in% names(self$nodes)) {
        stop(sprintf("from node '%s' must be an existing node ID string.", from))
      }
      if (!is.null(test) && !is.function(test)) stop("test must be a function.")

      prev <- self$conditional_edges[[from]] %||% list(test = NULL, if_true = NULL, if_false = NULL)

      self$conditional_edges[[from]] <- list(
        test = test %||% prev$test,
        if_true = if_true %||% prev$if_true,
        if_false = if_false %||% prev$if_false
      )

      if (is.null(self$conditional_edges[[from]]$test)) {
        stop(sprintf("No test function defined for conditional node '%s'.", from))
      }

      self$graph <- NULL
      invisible(self)
    },

    #' @description Add an Error Edge (Failover Support)
    #' @param from String node ID.
    #' @param to String node ID.
    #' @return The AgentDAG object (invisibly).
    add_error_edge = function(from, to) {
      if (!is.character(from) || length(from) != 1 || !from %in% names(self$nodes)) {
        stop(sprintf("from node '%s' must be an existing node ID string.", from))
      }
      if (!is.character(to) || length(to) != 1 || !to %in% names(self$nodes)) {
        stop(sprintf("to node '%s' must be an existing node ID string.", to))
      }

      self$error_edges[[from]] <- to
      invisible(self)
    },

    #' @description Run the Graph
    #' The primary execution engine for the \code{AgentDAG}. It manages the orchestration
    #' lifecycle, including state initialization / recovery, worktree setup for
    #' isolation, and routing between nodes. It automatically switches between
    #' linear (parallel-capable) and iterative execution modes based on the
    #' graph's complexity.
    #'
    #' @param initial_state List, AgentState, or String.
    #' The starting data for the workflow. Can be a named list of R objects,
    #' an existing \code{AgentState} instance, or a path to a checkpoint (if supported).
    #' Required unless resuming from a checkpointer.
    #' @param max_steps Integer.
    #' The maximum number of node executions allowed in a single \code{run()} call.
    #' Prevents infinite loops in cyclic graphs. Default is 25.
    #' @param checkpointer Checkpointer.
    #' An optional \code{Checkpointer} R6 object. If provided, the state is
    #' automatically saved after every node execution.
    #' @param thread_id String.
    #' A unique identifier for this execution "thread" or session. Required if
    #' using a \code{checkpointer} to resolve the correct state from storage.
    #' @param resume_from String.
    #' Optional node ID. If provided (or found in a checkpoint), execution will
    #' skip completed nodes and start from this point.
    #' @param use_worktrees Logical.
    #' Enable branch isolation. If \code{TRUE}, parallel branches are executed
    #' in separate git worktrees, preventing file-system conflicts between agents.
    #' @param repo_root String.
    #' Path to the master git repository. Required if \code{use_worktrees} is \code{TRUE}.
    #' @param cleanup_policy String.
    #' One of \code{"auto"} (default), \code{"none"}, or \code{"aggressive"}.
    #' Determines how worktrees are removed after execution.
    #' @param fail_if_dirty Logical.
    #' If \code{TRUE}, execution fails if the \code{repo_root} has uncommitted
    #' changes (recommended for reproducibility when using worktrees).
    #' @param packages Character vector.
    #' A list of R packages to load on parallel worker nodes (passed to \code{furrr}).
    #' @param ... Additional arguments.
    #' Passed down to individual \code{node$run()} calls.
    #'
    #' @return A list containing:
    #' \itemize{
    #'   \item \code{results}: A named list of each node's output.
    #'   \item \code{state}: The final \code{AgentState} object.
    #'   \item \code{status}: \code{"completed"} or \code{"paused"}.
    #' }
    run = function(initial_state = NULL,
                   max_steps = 25,
                   checkpointer = NULL,
                   thread_id = NULL,
                   resume_from = NULL,
                   use_worktrees = FALSE,
                   repo_root = getwd(),
                   cleanup_policy = "auto",
                   fail_if_dirty = TRUE,
                   packages = c("withr"),
                   ...) {
      self$compile()
      private$.fail_if_dirty <- fail_if_dirty
      private$.run_args <- list(...)
      private$.packages <- packages

      # 1. Thread and State Initialization
      if (is.null(thread_id)) {
        thread_id <- paste0("run-", substr(digest::digest(Sys.time()), 1, 8))
      }

      # Preallocation
      self$results <- vector("list", length(self$nodes))
      names(self$results) <- names(self$nodes)
      self$trace_log <- vector("list", max_steps)

      # 2. Checkpoint/State Recovery
      if (!is.null(checkpointer)) {
        stopifnot(inherits(checkpointer, "Checkpointer"))
        loaded_state <- checkpointer$get(thread_id)
        if (!is.null(loaded_state)) {
          cat(sprintf("[%s] [Iteration] Restored state from checkpoint for thread: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), thread_id))
          self$state <- if (is.null(initial_state)) {
            loaded_state
          } else {
            s <- loaded_state
            new_data <- if (inherits(initial_state, "AgentState")) initial_state$get_all() else initial_state
            purrr::iwalk(new_data, ~ s$set(.y, .x))
            s
          }

          # Restore results and trace_log if they exist
          saved_results <- self$state$get("__results__")
          if (!is.null(saved_results)) {
            # Merge saved results into current self$results
            purrr::iwalk(saved_results, function(val, nm) {
              if (!is.null(val)) self$results[[nm]] <- val
            })
          }
          saved_trace <- self$state$get("__trace_log__")
          if (!is.null(saved_trace)) {
            # Prepend saved_trace to self$trace_log
            len <- length(saved_trace)
            if (len > 0) {
              self$trace_log[1:len] <- saved_trace
            }
          }
        } else {
          if (is.null(initial_state)) stop("initial_state cannot be NULL if no checkpoint exists.")
          self$state <- if (inherits(initial_state, "AgentState")) initial_state else AgentState$new(initial_state)
        }
      } else {
        if (is.null(initial_state)) stop("initial_state cannot be NULL if not using a checkpointer.")
        self$state <- if (inherits(initial_state, "AgentState")) initial_state else AgentState$new(initial_state)
      }

      # 3. Unified Worktree Initialization
      if (use_worktrees) {
        cat(sprintf("[%s] [Worktree] Initializing WorktreeManager for thread: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), thread_id))
        self$worktree_manager <- WorktreeManager$new(
          repo_root = repo_root %||% getwd(),
          thread_id = thread_id,
          cleanup_policy = cleanup_policy
        )
        # Store in state so nodes (like MergeHarmonizer) can find it
        self$state$set("__worktree_manager__", self$worktree_manager)
      }

      # 4. Resume Logic
      auto_resume_nodes <- self$state$get("__next_nodes__")
      if (is.null(resume_from) && !is.null(auto_resume_nodes)) {
        resume_from <- auto_resume_nodes
      }

      # 5. Unified Execution Routing
      # If worktrees are enabled, we MUST use iterative mode to handle branch isolation.
      if (use_worktrees) {
        return(self$.run_iterative(max_steps, checkpointer, thread_id, resume_from, fail_if_dirty = fail_if_dirty, packages = packages))
      }

      # Check for Router Nodes
      has_router <- any(purrr::map_lgl(self$nodes, ~ inherits(.x, "AgentRouterNode")))

      # Calculate initial step count from restored trace log
      initial_step_count <- if (!is.null(self$state$get("__trace_log__"))) length(self$state$get("__trace_log__")) else 0

      # Default to linear if pure DAG and no complex features requested
      # complex features = conditional edges, error edges, or router nodes
      if (length(self$conditional_edges) == 0 && length(self$error_edges) == 0 && !has_router && igraph::is_dag(self$graph)) {
        return(self$.run_linear(max_steps, checkpointer, thread_id, resume_from, step_count = initial_step_count, fail_if_dirty = fail_if_dirty))
      }

      # Fallback to iterative for cycles, conditional logic, and dynamic routing
      return(self$.run_iterative(max_steps, checkpointer, thread_id, resume_from, step_count = initial_step_count, fail_if_dirty = fail_if_dirty))
    },

    #' Internal: Linear DAG Execution
    #' @param max_steps Integer.
    #' @param checkpointer Checkpointer object.
    #' @param thread_id String thread ID.
    #' @param resume_from Node ID(s) to resume from.
    #' @param node_ids Character vector of nodes to run.
    #' @param step_count Integer current total step count.
    #' @param fail_if_dirty Logical.
    #' @return Execution result list.
    .run_linear = function(max_steps = 25,
                           checkpointer = NULL,
                           thread_id = NULL,
                           resume_from = NULL,
                           node_ids = NULL,
                           step_count = 0,
                           fail_if_dirty = TRUE) {
      if (is.null(node_ids)) {
        topo_order <- igraph::topo_sort(self$graph)
        node_ids <- names(igraph::V(self$graph)[topo_order])

        if (!is.null(resume_from)) {
          resume_idx <- match(resume_from[1], node_ids)
          if (!is.na(resume_idx)) {
            node_ids <- node_ids[resume_idx:length(node_ids)]
            cat(sprintf("[%s] [Resuming] Linear DAG Execution from node: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), resume_from[1]))
          }
        }
      }

      # Use purrr::walk instead of while to comply with APAF Zero-Tolerance Policy
      env <- new.env(parent = emptyenv())
      env$paused_at <- NULL
      env$node_ids <- node_ids
      env$step_count <- step_count

      purrr::walk(seq_along(node_ids), function(i) {
        if (!is.null(env$paused_at)) {
          return()
        }

        node_id <- env$node_ids[1]
        env$node_ids <- env$node_ids[-1]

        if ((env$step_count + 1) > length(self$trace_log)) {
          warning(sprintf("Execution limit reached in .run_linear for thread: %s. Saving state for restart.", thread_id %||% "unknown"))
          env$paused_at <- node_id
          return()
        }

        cat(sprintf("[%s] [Linear] Running Node: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), node_id))

        restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)

        start_time <- Sys.time()
        res <- self$nodes[[node_id]]$run(restricted_state)
        end_time <- Sys.time()

        self$results[[node_id]] <- res

        if (!is.null(res$output)) {
          self$state$update_from_node(res$output, node_id)
        }

        env$step_count <- env$step_count + 1
        self$trace_log[[env$step_count]] <- list(
          step = env$step_count, node = node_id, mode = "linear",
          start_time = as.character(start_time), end_time = as.character(end_time),
          duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
          status = res$status, error = res$error
        )

        self$state$set("__results__", self$results)
        self$state$set("__trace_log__", self$trace_log[seq_len(env$step_count)])
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

        if (!is.null(res$status) && res$status == "pause") {
          env$paused_at <- node_id
        }
      })

      if (!is.null(env$paused_at)) {
        self$trace_log <- self$trace_log[seq_len(env$step_count)]
        self$state$set("__next_nodes__", if (length(env$node_ids) > 0) env$node_ids else NULL)
        self$state$set("__results__", self$results)
        self$state$set("__trace_log__", self$trace_log)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = env$paused_at))
      }

      self$trace_log <- self$trace_log[seq_len(env$step_count)]
      self$state$set("__next_nodes__", NULL)
      self$state$set("__results__", self$results)
      self$state$set("__trace_log__", self$trace_log)
      if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
      return(list(results = self$results, state = self$state, status = "completed"))
    },

    #' Internal: Iterative Execution
    #' @param max_steps Integer.
    #' @param checkpointer Checkpointer object.
    #' @param thread_id String.
    #' @param resume_from String.
    #' @param step_count Integer.
    #' @param fail_if_dirty Logical.
    #' @param packages Character vector. Packages to load in parallel workers.
    .run_iterative = function(max_steps,
                              checkpointer = NULL,
                              thread_id = NULL,
                              resume_from = NULL,
                              step_count = 0,
                              fail_if_dirty = TRUE,
                              packages = c("withr")) {
      current_nodes <- if (!is.null(resume_from)) {
        cat(sprintf("[%s] [Resuming] Resuming Iterative DAG Execution from node(s): %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), paste(resume_from, collapse = ", ")))
        resume_from
      } else if (!is.null(self$start_node)) {
        self$start_node
      } else {
        names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
      }

      if (length(current_nodes) == 0) stop("No start nodes found.")

      # Use purrr::walk instead of while/for to comply with APAF Zero-Tolerance Policy
      env <- new.env(parent = emptyenv())
      env$paused_at <- NULL
      env$completed <- FALSE
      env$step_count <- step_count
      env$current_nodes <- current_nodes
      env$next_queue <- character(0)

      purrr::walk(seq_len(max_steps), function(step_idx) {
        if (!is.null(env$paused_at) || env$completed || env$step_count >= max_steps) {
          return()
        }
        if (length(env$current_nodes) == 0) {
          env$completed <- TRUE
          return()
        }

        env$next_queue <- character(0)

        # Parallel Execution Block
        nodes_to_run_parallel <- if (!is.null(self$worktree_manager)) env$current_nodes else character(0)

        if (length(nodes_to_run_parallel) > 0) {
          cat(sprintf("[%s] [Parallel] Executing %d nodes in isolated worktrees using furrr...\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), length(nodes_to_run_parallel)))
          self$state$set("__worktree_manager__", self$worktree_manager)
          self$state$set("__fail_if_dirty__", private$.fail_if_dirty)
          purrr::walk(nodes_to_run_parallel, ~ self$worktree_manager$create(.x, fail_if_dirty = private$.fail_if_dirty))

          parallel_results <- furrr::future_map(nodes_to_run_parallel, function(node_id) {
            node <- self$nodes[[node_id]]
            wt_path <- self$worktree_manager$get_path(node_id)
            if (inherits(node, "AgentLLMNode") && !is.null(node$driver)) {
              node$driver$working_dir <- wt_path
              # Pass the main project root to satisfy IDE-locked CLI checks
              if (!is.null(self$worktree_manager)) {
                node$driver$repo_root <- self$worktree_manager$repo_root
              }
            }
            withr::with_dir(wt_path, {
              restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)
              st <- Sys.time()
              run_call <- list(state = restricted_state)
              run_call <- utils::modifyList(run_call, self$.__enclos_env__$private$.run_args %||% list())
              res <- do.call(node$run, run_call)
              et <- Sys.time()
              list(id = node_id, res = res, start = st, end = et)
            })
          }, .options = furrr::furrr_options(globals = c("self"), packages = packages))

          # Integrate results and collect next nodes
          purrr::walk(parallel_results, function(p_res) {
            node_id <- p_res$id
            res <- p_res$res
            self$results[[node_id]] <- res
            if (!is.null(res$output)) {
              self$state$update_from_node(res$output, node_id)
            }
            env$step_count <- env$step_count + 1
            self$trace_log[[env$step_count]] <- list(
              step = env$step_count, node = node_id, mode = "parallel",
              start_time = as.character(p_res$start), end_time = as.character(p_res$end),
              duration_secs = as.numeric(difftime(p_res$end, p_res$start, units = "secs")),
              status = res$status,
              error = if (!is.null(res$error)) as.character(res$error) else if (res$status == "failed" && !is.null(p_res$error)) as.character(p_res$error) else NULL
            )
            self$state$set("__results__", self$results)
            self$state$set("__trace_log__", self$trace_log[seq_len(env$step_count)])
            if (!is.null(res$status) && tolower(res$status) == "pause") {
              env$paused_at <- node_id
              env$completed <- TRUE
            }

            # Successors Logic (Unified Routing)
            target <- NULL

            # 1. Error Edge (Highest priority if failed)
            if (!is.null(res$status) && res$status %in% c("failed", "error") && node_id %in% names(self$error_edges)) {
              cat(sprintf("[%s]    [%s] Node failed (Parallel). Following error edge to: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), node_id, self$error_edges[[node_id]]))
              target <- self$error_edges[[node_id]]
            }
            # 2. Dynamic Router Output
            else if (!is.null(res$target_node)) {
              cat(sprintf("[%s]    [%s] Router (Parallel) selected next node: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), node_id, res$target_node))
              target <- res$target_node
            }
            # 3. Conditional Edges
            else if (node_id %in% names(self$conditional_edges)) {
              cond <- self$conditional_edges[[node_id]]
              test_passed <- tryCatch(cond$test(res), error = function(e) FALSE)
              target <- if (test_passed) cond$if_true else cond$if_false
            }
            # 4. Standard Edges (Multi-branch)
            else {
              children <- names(igraph::adjacent_vertices(self$graph, node_id, mode = "out")[[1]])
              if (length(children) > 0) {
                env$next_queue <- unique(c(env$next_queue, children))
              }
            }

            if (!is.null(target)) {
              env$next_queue <- unique(c(env$next_queue, target))
            }
          })
          if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        } else {
          # Sequential Execution Block - Using purrr::walk instead of for()
          purrr::walk(env$current_nodes, function(node_id) {
            if (!is.null(env$paused_at)) {
              return()
            }
            step_idx_inner <- env$step_count + 1
            if (step_idx_inner > max_steps) {
              return()
            }

            cat(sprintf("[%s] [DEBUG] Queue: %s | Running: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), paste(env$current_nodes, collapse = ", "), node_id))

            restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)
            start_time <- Sys.time()
            run_call <- list(state = restricted_state)
            run_call <- utils::modifyList(run_call, self$.__enclos_env__$private$.run_args %||% list())
            res <- do.call(self$nodes[[node_id]]$run, run_call)
            end_time <- Sys.time()

            self$results[[node_id]] <- res
            if (!is.null(res$output)) {
              self$state$update_from_node(res$output, node_id)
            }
            self$trace_log[[step_idx_inner]] <- list(
              step = step_idx_inner, node = node_id, mode = "iterative",
              start_time = as.character(start_time), end_time = as.character(end_time),
              duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
              status = res$status, error = res$error
            )
            env$step_count <- step_idx_inner

            self$state$set("__results__", self$results)
            self$state$set("__trace_log__", self$trace_log[seq_len(env$step_count)])

            if (!is.null(res$status) && tolower(res$status) == "pause") {
              env$paused_at <- node_id
              env$completed <- TRUE
              env$next_queue <- character(0) # Clear the queue to ensure we stop immediately
              if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
              return()
            }
            if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

            # Successors Logic (Unified Routing)
            target <- NULL

            # 1. Error Edge (Highest priority if failed)
            if (!is.null(res$status) && res$status %in% c("failed", "error") && node_id %in% names(self$error_edges)) {
              cat(sprintf("[%s]    [%s] Node failed. Following error edge to: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), node_id, self$error_edges[[node_id]]))
              target <- self$error_edges[[node_id]]
            }
            # 2. Dynamic Router Output
            else if (!is.null(res$target_node)) {
              cat(sprintf("[%s]    [%s] Router selected next node: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), node_id, res$target_node))
              target <- res$target_node
            }
            # 3. Conditional Edges
            else if (node_id %in% names(self$conditional_edges)) {
              cond <- self$conditional_edges[[node_id]]
              test_passed <- tryCatch(cond$test(res), error = function(e) FALSE)
              target <- if (test_passed) cond$if_true else cond$if_false
            }
            # 4. Standard Edges (Multi-branch)
            else {
              children <- names(igraph::adjacent_vertices(self$graph, node_id, mode = "out")[[1]])
              if (length(children) > 0) {
                env$next_queue <- unique(c(env$next_queue, children))
              }
            }

            if (!is.null(target)) {
              env$next_queue <- unique(c(env$next_queue, target))
            }
          })
        }

        env$current_nodes <- env$next_queue
      })

      if (env$step_count >= max_steps) warning("Reached max_steps.")
      self$trace_log <- self$trace_log[seq_len(env$step_count)]
      self$state$set("__next_nodes__", if (length(env$current_nodes) > 0) env$current_nodes else NULL)
      self$state$set("__results__", self$results)
      self$state$set("__trace_log__", self$trace_log)
      if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

      final_status <- if (!is.null(env$paused_at) || length(env$current_nodes) > 0) {
        "paused"
      } else {
        "completed"
      }

      return(list(
        results = self$results,
        state = self$state,
        status = final_status,
        paused_at = env$paused_at
      ))
    },

    #' Visualize the Graph
    #'
    #' @description
    #' Generates a visual representation of the DAG using Mermaid or DOT syntax.
    #'
    #' @param type String.
    #' Either \code{"mermaid"} (default) for web-native rendering or \code{"grViz"}
    #' for DiagrammeR/Graphviz.
    #' @param status Logical.
    #' If \code{TRUE}, colors nodes based on the results in the current trace log
    #' (Green: Success, Red: Failed, Yellow: Paused).
    #' @param details Logical.
    #' If \code{TRUE}, injects node parameters into the labels.
    #' @param include_params Character vector.
    #' Optional whitelist of parameter names to display when \code{details} is \code{TRUE}.
    #' @param show_edge_labels Logical.
    #' Whether to display labels (e.g., "Test", "Fail") on edges.
    #'
    #' @return The Mermaid/DOT source string (invisibly).
    #'
    #' @examples
    #' \dontrun{
    #' dag <- dag_create()
    #' dag$add_node(AgentNode$new("A"))
    #' dag$add_node(AgentNode$new("B"))
    #' dag$add_edge("A", "B", label = "proceed")
    #'
    #' # Generate Mermaid string
    #' m_src <- dag$plot(type = "mermaid", show_edge_labels = TRUE)
    #' cat(m_src)
    #' }
    plot = function(type = "mermaid", status = FALSE, details = FALSE, include_params = NULL, show_edge_labels = TRUE) {
      if (!type %in% c("mermaid", "grViz")) stop("Only 'mermaid' and 'grViz' types are supported.")

      # 1. Define Nodes
      node_lines <- purrr::map_chr(names(self$nodes), function(node_id) {
        node <- self$nodes[[node_id]]
        lbl <- node$label

        if (status && !is.null(self$results[[node_id]])) {
          res <- self$results[[node_id]]
          out_val <- res$output
          if (is.character(out_val) || is.numeric(out_val)) {
            lbl <- paste(lbl, sprintf("(%s)", as.character(out_val)), sep = " ")
          } else if (is.list(out_val) && !is.null(out_val$final_consensus)) {
            lbl <- paste(lbl, sprintf("[%s]", out_val$final_consensus), sep = " ")
          }
        }

        if (details && length(node$params) > 0) {
          p_list <- if (is.null(include_params)) {
            node$params
          } else {
            node$params[names(node$params) %in% include_params]
          }

          if (length(p_list) > 0) {
            p_str <- purrr::imap_chr(p_list, function(v, k) {
              val_str <- if (is.null(v)) "null" else as.character(v)
              sprintf("%s=%s", k, val_str)
            }) |> paste(collapse = " | ")
            lbl <- paste(lbl, p_str, sep = " | ")
          }
        }

        if (identical(type, "mermaid")) {
          sprintf("  %s[\"%s\"]", node_id, lbl)
        } else {
          # DOT: Escape quotes in labels
          safe_lbl <- gsub("\"", "\\\"", lbl, fixed = TRUE)

          # Handle status-based styling for DOT
          style_attr <- NULL
          if (status && !is.null(self$results[[node_id]])) {
            status_val <- self$results[[node_id]]$status %||% ""
            if (identical(status_val, "success")) {
              style_attr <- "fillcolor=\"#c8e6c9\", color=\"#2e7d32\""
            } else if (status_val %in% c("failed", "error")) {
              style_attr <- "fillcolor=\"#ff8a80\", color=\"#b71c1c\""
            } else if (identical(status_val, "pause")) {
              style_attr <- "fillcolor=\"#fff9c4\", color=\"#fbc02d\""
            }
          }

          attrs <- purrr::compact(list(sprintf("label=\"%s\"", safe_lbl), style_attr)) |> paste(collapse = ", ")
          sprintf("  %s [%s];", node_id, attrs)
        }
      })

      # 2. Collect All Possible Edges
      env <- new.env(parent = emptyenv())
      env$all_edges_list <- list()

      # Standard edges
      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) do.call(rbind, self$edges) else self$edges
      if (inherits(edges_df, "data.frame") && nrow(edges_df) > 0) {
        purrr::walk(seq_len(nrow(edges_df)), function(i) {
          lbl <- if (is.na(edges_df$label[i])) NULL else edges_df$label[i]
          env$all_edges_list[[length(env$all_edges_list) + 1]] <- list(from = edges_df$from[i], to = edges_df$to[i], label = lbl)
        })
      }

      # Conditional edges
      sorted_cond_from <- sort(names(self$conditional_edges))
      purrr::walk(sorted_cond_from, function(from) {
        cond <- self$conditional_edges[[from]]
        if (!is.null(cond$if_true)) {
          env$all_edges_list[[length(env$all_edges_list) + 1]] <- list(from = from, to = cond$if_true, label = "Test", type = "cond")
        }
        if (!is.null(cond$if_false)) {
          env$all_edges_list[[length(env$all_edges_list) + 1]] <- list(from = from, to = cond$if_false, label = "Fail", type = "cond")
        }
      })

      # Error edges
      sorted_err_from <- sort(names(self$error_edges))
      purrr::walk(sorted_err_from, function(from) {
        target <- self$error_edges[[from]]
        env$all_edges_list[[length(env$all_edges_list) + 1]] <- list(from = from, to = target, label = "error", type = "error")
      })

      # Generate edge lines
      executed_nodes <- if (status && length(self$trace_log) > 0) purrr::map_chr(purrr::compact(self$trace_log), ~ .x$node) else character(0)

      edge_lines <- purrr::imap_chr(env$all_edges_list, function(e, idx) {
        if (identical(type, "mermaid")) {
          if (show_edge_labels && !is.null(e$label)) {
            sprintf("  %s -- %s --> %s", e$from, e$label, e$to)
          } else {
            sprintf("  %s --> %s", e$from, e$to)
          }
        } else {
          # DOT:
          lbl_attr <- if (show_edge_labels && !is.null(e$label)) sprintf("label=\"%s\"", e$label) else NULL
          style_attr <- NULL

          # Highlight as TRAVERSED
          if (e$from %in% executed_nodes && e$to %in% executed_nodes) {
            color <- if (identical(e$type, "error")) "#e53935" else "#388e3c"
            style_attr <- sprintf("color=\"%s\", penwidth=3", color)
          } else if (identical(e$type, "error")) {
            style_attr <- "color=\"#e53935\", style=\"dashed\""
          }

          attrs <- purrr::compact(list(lbl_attr, style_attr)) |> paste(collapse = ", ")
          attr_str <- if (nzchar(attrs)) sprintf(" [%s]", attrs) else ""
          sprintf("  %s -> %s%s;", e$from, e$to, attr_str)
        }
      })

      env$extra_lines <- character()
      if (identical(type, "mermaid") && status && length(self$results) > 0) {
        # Class Definitions for Mermaid
        env$extra_lines <- c(
          "  classDef success fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;",
          "  classDef failure fill:#ff8a80,stroke:#b71c1c,stroke-width:2px;",
          "  classDef active fill:#bbdefb,stroke:#0d47a1,stroke-width:2px;",
          "  classDef pause fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;"
        )

        purrr::iwalk(self$results, function(res, node_id) {
          status_val <- res$status %||% ""
          cls <- if (identical(status_val, "success")) "success" else if (status_val %in% c("failed", "error")) "failure" else if (identical(status_val, "pause")) "pause" else NULL
          if (!is.null(cls)) env$extra_lines <- c(env$extra_lines, sprintf("  class %s %s", node_id, cls))
        })

        if (length(self$trace_log) > 0) {
          purrr::iwalk(env$all_edges_list, function(e, idx) {
            if (identical(e$type, "error")) {
              env$extra_lines <- c(env$extra_lines, sprintf("  linkStyle %d stroke:#e53935,stroke-width:2px,stroke-dasharray: 5 5;", idx - 1))
            }
            if (e$from %in% executed_nodes && e$to %in% executed_nodes) {
              color <- if (identical(e$type, "error")) "#e53935" else "#388e3c"
              env$extra_lines <- c(env$extra_lines, sprintf("  linkStyle %d stroke:%s,stroke-width:4px;", idx - 1, color))
            }
          })
        }
      }

      if (identical(type, "mermaid")) {
        lines <- c("```mermaid", "graph TD", node_lines, edge_lines, env$extra_lines, "```")
      } else {
        lines <- c("digraph {", "  rankdir=TB;", "  node [shape=box, style=filled, fontname=Helvetica, fillcolor=white];", node_lines, edge_lines, "}")
      }

      res <- paste(lines, collapse = "\n")
      cat(res, "\n")
      return(invisible(res))
    },

    #' @description Get Terminal Nodes
    #' Identifies nodes with no outgoing edges.
    #' @return Character vector of node IDs.
    get_terminal_nodes = function() {
      private$.rebuild_graph()
      names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "out") == 0])
    },

    #' @description Get Start Nodes (Roots)
    #' Identifies nodes with no incoming edges.
    #' @return Character vector of node IDs.
    get_start_nodes = function() {
      private$.rebuild_graph()
      names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
    },

    #' Compile the Graph
    #'
    #' @description
    #' Rebuilds the internal \code{igraph} representation and performs validation
    #' checks such as cycle detection, start node disambiguation, and
    #' reachability analysis. This must be called before \code{run()}.
    #'
    #' @details
    #' Compilation will throw errors if:
    #' \itemize{
    #'   \item Cycles are found in a pure DAG (no conditional edges).
    #'   \item Multiple root nodes are found without an explicit \code{start_node}.
    #'   \item Node IDs used in edges do not exist.
    #' }
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    compile = function() {
      private$.rebuild_graph()
      if (length(self$nodes) == 0) stop("No nodes in graph.")

      # Validation: Cycle Detection for pure DAGs
      if (length(self$conditional_edges) == 0) {
        if (!igraph::is_dag(self$graph)) {
          stop("Circular dependency detected in pure DAG. Ensure edges do not form cycles or use add_conditional_edge() for loops.")
        }
      }

      # Validation: Ambiguous Start Nodes
      if (is.null(self$start_node)) {
        roots <- self$get_start_nodes()
        if (length(roots) > 1) {
          warning(sprintf("Multiple potential start nodes found (%s). Use set_start_node() to disambiguate.", paste(roots, collapse = ", ")))
        } else if (length(roots) == 0 && length(self$nodes) > 0) {
          warning("Graph contains cycles but no start node is explicitly set. Execution may fail.")
        }
      }

      # Validation: Reachable nodes if start_node is set
      if (!is.null(self$start_node)) {
        env <- new.env(parent = emptyenv())
        env$all_reachable <- character(0)
        purrr::walk(self$start_node, function(root_id) {
          reachable <- igraph::bfs(self$graph, root = root_id, unreachable = FALSE)$order
          reachable_names <- names(igraph::V(self$graph)[reachable[!is.na(reachable)]])
          env$all_reachable <- unique(c(env$all_reachable, reachable_names))
        })
        unreachable <- setdiff(names(self$nodes), env$all_reachable)
        if (length(unreachable) > 0) {
          warning(sprintf("Nodes unreachable from start node(s) [%s]: %s", paste(self$start_node, collapse = ", "), paste(unreachable, collapse = ", ")))
        }
      }

      # Optional: Check for potential infinite loops if cycles exist with conditional tests
      if (!igraph::is_dag(self$graph)) {
        # This is more complex, but a general warning is helpful
        warning("Potential infinite loop detected: graph contains cycles. Ensure conditional edges have exit conditions.")
      }

      cat("Graph compiled successfully.\n")
      invisible(self)
    },

    #' Save the Execution Trace
    #'
    #' @description
    #' Exports the detailed telemetry from the last execution (durations,
    #' status, outputs) to a JSON file.
    #'
    #' @param file String.
    #' Path to the output JSON file. Defaults to \code{"dag_trace.json"}.
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    save_trace = function(file = "dag_trace.json") {
      jsonlite::write_json(self$trace_log, path = file, pretty = TRUE, auto_unbox = TRUE)
      cat(sprintf("[Saved] Saved execution trace to: %s\n", file))
      invisible(self)
    },

    #' Create Graph from Mermaid
    #'
    #' @description
    #' A static-like method to populate a DAG from a Mermaid string using a
    #' custom node factory.
    #'
    #' @param mermaid_str String.
    #' A valid Mermaid graph definition (e.g., \code{"graph TD; A-->B"}).
    #' @param node_factory Function.
    #' A closure mapping Mermaid labels and parameters to \code{AgentNode}
    #' instances. See \code{\link{auto_node_factory}} for the standard
    #' implementation.
    #'
    #' @return The \code{AgentDAG} object (invisibly).
    #'
    #' @examples
    #' \dontrun{
    #' # Use a custom factory to map all nodes to Logic nodes
    #' simple_factory <- function(id, label, params) {
    #'   AgentLogicNode$new(id = id, logic_fn = function(s) list(status="ok"))
    #' }
    #'
    #' dag <- AgentDAG$new()
    #' dag$from_mermaid("graph LR; Start-->End", simple_factory)
    #' }
    from_mermaid = function(mermaid_str, node_factory) {
      stopifnot(is.function(node_factory))
      parsed <- parse_mermaid(mermaid_str)

      # Add nodes
      purrr::pwalk(parsed$nodes, function(id, label, params) {
        # Support both 2-arg and 3-arg factories for robustness
        # Logic: if factory has >=3 args, pass params. Otherwise just id/label.
        n_args <- length(formals(node_factory))
        node <- if (n_args >= 3) {
          node_factory(id, label, params)
        } else {
          node_factory(id, label)
        }

        if (!is.null(node)) {
          # Ensure node has params if factory didn't set them
          if (length(node$params) == 0 && length(params) > 0) {
            node$params <- params
          }
          self$add_node(node)
        }
      })

      # Add edges
      purrr::walk(seq_len(nrow(parsed$edges)), function(i) {
        from <- parsed$edges$from[i]
        to <- parsed$edges$to[i]
        label <- parsed$edges$label[i]

        # Pass the label if it's non-empty
        lbl <- if (nzchar(label)) label else NULL
        self$add_edge(from, to, label = lbl)
      })

      invisible(self)
    }
  ),
  private = list(
    .fail_if_dirty = TRUE,
    .run_args = list(),
    .packages = c("withr"),
    .rebuild_graph = function() {
      if (!is.null(self$graph)) {
        return(invisible(self))
      } # Cache hit

      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) {
        do.call(rbind, self$edges)
      } else if (is.data.frame(self$edges)) {
        self$edges
      } else {
        data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
      }

      # Incorporate Conditional Edges into the graph for analysis
      if (length(self$conditional_edges) > 0) {
        cond_edges <- purrr::imap(self$conditional_edges, function(cond, from) {
          df_list <- list()
          if (!is.null(cond$if_true)) {
            df_list[[length(df_list) + 1]] <- data.frame(from = from, to = cond$if_true, label = NA_character_, stringsAsFactors = FALSE)
          }
          if (!is.null(cond$if_false)) {
            df_list[[length(df_list) + 1]] <- data.frame(from = from, to = cond$if_false, label = NA_character_, stringsAsFactors = FALSE)
          }
          if (length(df_list) == 0) {
            return(NULL)
          }
          do.call(rbind, df_list)
        }) |>
          purrr::compact() |>
          purrr::list_rbind()

        if (!is.null(cond_edges) && nrow(cond_edges) > 0) {
          edges_df <- rbind(edges_df, cond_edges)
        }
      }

      # Incorporate Error Edges into the graph for analysis
      if (length(self$error_edges) > 0) {
        err_edges <- purrr::imap(self$error_edges, function(to, from) {
          data.frame(from = from, to = to, label = NA_character_, stringsAsFactors = FALSE)
        }) |>
          purrr::list_rbind()

        if (!is.null(err_edges) && nrow(err_edges) > 0) {
          edges_df <- rbind(edges_df, err_edges)
        }
      }

      # Validation Engine: Detect undefined nodes in edges
      if (nrow(edges_df) > 0) {
        all_node_ids <- names(self$nodes)
        referenced_nodes <- unique(c(edges_df$from, edges_df$to))
        undefined_nodes <- setdiff(referenced_nodes, all_node_ids)
        if (length(undefined_nodes) > 0) {
          stop(sprintf("Undefined node(s) referenced in edges: %s", paste(undefined_nodes, collapse = ", ")))
        }

        self$graph <- igraph::graph_from_data_frame(edges_df, directed = TRUE, vertices = data.frame(name = all_node_ids))
      } else {
        self$graph <- igraph::make_empty_graph(n = length(self$nodes), directed = TRUE)
        igraph::V(self$graph)$name <- names(self$nodes)
      }
      invisible(self)
    }
  )
)

# Create AgentDAG from Mermaid (Static Method for backward compatibility)
AgentDAG$from_mermaid <- function(mermaid_str, node_factory = auto_node_factory()) {
  dag <- AgentDAG$new()
  dag$from_mermaid(mermaid_str, node_factory)
  return(dag)
}

#' Create AgentDAG from Mermaid
#' @param mermaid_str String. Mermaid syntax.
#' @param node_factory Function(id, label) -> AgentNode. Defaults to `auto_node_factory()`.
#' @return The AgentDAG object.
#' @examples
#' \dontrun{
#' # 1. High-level 'Logic-First' graph
#' # Mapping Mermaid node labels to registered R functions
#' dag1 <- mermaid_to_dag("graph TD; A[logic:fetch]-->B[logic:validate];")
#'
#' # 2. Complex 'Agent-First' graph with extended metadata
#' # Explicitly defining roles, drivers, and models inside attributes
#' mermaid_src <- '
#' graph TD
#'   A["Researcher | type=llm | role=Expert Analyst | model=sonnet"]
#'   B["Critic | type=llm | role=Scientific Reviewer | temp=0.2"]
#'   C["Refiner | type=logic | logic_id=refine_markdown"]
#'
#'   A --> B
#'   B -- (feedback_required) --> A
#'   B -- (approved) --> C
#' '
#'
#' # Spawning the DAG
#' dag2 <- mermaid_to_dag(mermaid_src)
#'
#' # Verification
#' print(dag2$nodes$A$role) # "Expert Analyst"
#' }
#' @export
mermaid_to_dag <- function(mermaid_str, node_factory = auto_node_factory()) {
  dag <- AgentDAG$new()
  dag$from_mermaid(mermaid_str, node_factory)
  return(dag)
}

#' <!-- APAF Bioinformatics | dag.R | Approved | 2026-03-30 -->

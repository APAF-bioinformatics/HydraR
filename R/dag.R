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
#' Defines and executes a Directed Graph of AgentNodes.
#' Supports both pure DAG execution (parallel) and iterative loops via conditional edges.
#'
#' @return An `AgentDAG` R6 object.
#' @examples
#' dag <- AgentDAG$new()
#' node <- AgentLogicNode$new("start", function(state) list(status = "success"))
#' dag$add_node(node)
#' @importFrom R6 R6Class
#' @importFrom digest digest
#' @importFrom jsonlite toJSON fromJSON write_json
#' @importFrom igraph graph_from_data_frame is_dag topo_sort edge V vcount make_empty_graph degree is_connected components bfs
#' @importFrom furrr future_map
#' @importFrom purrr map set_names iwalk walk
#' @examples
#' \dontrun{
#' dag <- AgentDAG$new()
#' dag$add_node(AgentNode$new("A"))
#' dag$add_node(AgentNode$new("B"))
#' dag$add_edge("A", "B")
#' dag$set_start_node("A")
#' dag$compile()
#' }
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

    #' @description
    #' Initialize AgentDAG
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

    #' Set Start Node
    #' @param node_id String node ID.
    #' @return The AgentDAG object (invisibly).
    set_start_node = function(node_id) {
      if (!is.character(node_id) || length(node_id) != 1) {
        stop("node_id must be a single string.")
      }
      if (!node_id %in% names(self$nodes)) {
        stop(sprintf("Node '%s' not found in DAG. Add the node before setting it as start.", node_id))
      }
      self$start_node <- node_id
      invisible(self)
    },

    #' Add a Node
    #' @param node AgentNode object.
    #' @return The AgentDAG object (invisibly).
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

    #' Add an Edge
    #' @param from String or character vector of node IDs.
    #' @param to String node ID.
    #' @param label Optional string label for the edge.
    #' @return The AgentDAG object (invisibly).
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

    #' Add a Conditional Edge (Loop Support)
    #' @param from String node ID.
    #' @param test Function(output) -> Logical.
    #' @param if_true String node ID (next node if test is TRUE) or NULL.
    #' @param if_false String node ID (next node if test is FALSE) or NULL.
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

    #' Add an Error Edge (Failover Support)
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

    #' Run the Graph
    #' @param initial_state List, AgentState object, or String. Optional if resuming.
    #' @param max_steps Integer. Maximum iterations to prevent infinite loops. Default is 25.
    #' @param checkpointer Checkpointer object. Optional.
    #' @param thread_id String. Identifier for the execution thread. Required if using checkpointer.
    #' @param resume_from String. Node ID to resume execution from.
    #' @param use_worktrees Logical. Whether to use isolated git worktrees for parallel branches.
    #' @param repo_root String. Path to the main git repository.
    #' @param cleanup_policy String. "auto", "none", or "aggressive".
    #' @param fail_if_dirty Logical. Whether to fail if repo has uncommitted changes.
    #' @param packages Character vector. Packages to load in parallel workers.
    #' @param ... Additional arguments passed to node run methods.

    #' @return List of results for each node, and the final state.
    run = function(initial_state = NULL,
                   max_steps = 25,
                   checkpointer = NULL,
                   thread_id = NULL,
                   resume_from = NULL,
                   use_worktrees = FALSE,
                   repo_root = getwd(),
                   cleanup_policy = "auto",
                   fail_if_dirty = TRUE,
                   packages = c("withr", "HydraR"),
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
          cat(sprintf("[Iteration] Restored state from checkpoint for thread: %s\n", thread_id))
          self$state <- if (is.null(initial_state)) {
            loaded_state
          } else {
            s <- loaded_state
            new_data <- if (inherits(initial_state, "AgentState")) initial_state$get_all() else initial_state
            purrr::iwalk(new_data, ~ s$set(.y, .x))
            s
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
        cat(sprintf("[Worktree] Initializing WorktreeManager for thread: %s\n", thread_id))
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

      # Default to linear if pure DAG and no complex features requested
      # complex features = conditional edges, error edges, or router nodes
      if (length(self$conditional_edges) == 0 && length(self$error_edges) == 0 && !has_router && igraph::is_dag(self$graph)) {
        return(self$.run_linear(max_steps, checkpointer, thread_id, resume_from, fail_if_dirty = fail_if_dirty))
      }

      # Fallback to iterative for cycles, conditional logic, and dynamic routing
      return(self$.run_iterative(max_steps, checkpointer, thread_id, resume_from, fail_if_dirty = fail_if_dirty))
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
    .run_linear = function(max_steps = 25, checkpointer = NULL, thread_id = NULL, resume_from = NULL, node_ids = NULL, step_count = 0, fail_if_dirty = TRUE) {
      if (is.null(node_ids)) {
        topo_order <- igraph::topo_sort(self$graph)
        node_ids <- names(igraph::V(self$graph)[topo_order])

        if (!is.null(resume_from)) {
          resume_idx <- match(resume_from[1], node_ids)
          if (!is.na(resume_idx)) {
            node_ids <- node_ids[resume_idx:length(node_ids)]
            cat(sprintf("[Resuming] Linear DAG Execution from node: %s\n", resume_from[1]))
          }
        }
      }

      # Use purrr::walk instead of while to comply with APAF Zero-Tolerance Policy
      paused_at <- NULL
      purrr::walk(seq_along(node_ids), function(i) {
        if (!is.null(paused_at)) {
          return()
        }

        node_id <- node_ids[1]
        node_ids <<- node_ids[-1]

        if ((step_count + 1) > length(self$trace_log)) {
          warning(sprintf("Execution limit reached in .run_linear for thread: %s. Saving state for restart.", thread_id %||% "unknown"))
          paused_at <<- node_id
          return()
        }

        cat(sprintf("[Linear] Running Node: %s\n", node_id))
        restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)

        start_time <- Sys.time()
        res <- self$nodes[[node_id]]$run(restricted_state)
        end_time <- Sys.time()

        self$results[[node_id]] <<- res

        if (!is.null(res$output)) {
          if (is_named_list(res$output)) {
            self$state$update(res$output)
          } else {
            self$state$update(setNames(list(res$output), node_id))
          }
        }

        step_count <<- step_count + 1
        self$trace_log[[step_count]] <<- list(
          step = step_count, node = node_id, mode = "linear",
          start_time = as.character(start_time), end_time = as.character(end_time),
          duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
          status = res$status, error = res$error
        )

        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

        if (!is.null(res$status) && res$status == "pause") {
          paused_at <<- node_id
        }
      })

      if (!is.null(paused_at)) {
        self$trace_log <- self$trace_log[seq_len(step_count)]
        self$state$set("__next_nodes__", if (length(node_ids) > 0) node_ids else NULL)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = paused_at))
      }

      self$trace_log <- self$trace_log[seq_len(step_count)]
      self$state$set("__next_nodes__", NULL)
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
    .run_iterative = function(max_steps, checkpointer = NULL, thread_id = NULL, resume_from = NULL, step_count = 0, fail_if_dirty = TRUE, packages = c("withr", "HydraR")) {
      current_nodes <- if (!is.null(resume_from)) {
        cat(sprintf("[Resuming] Resuming Iterative DAG Execution from node(s): %s\n", paste(resume_from, collapse = ", ")))
        resume_from
      } else if (!is.null(self$start_node)) {
        self$start_node
      } else {
        names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
      }

      if (length(current_nodes) == 0) stop("No start nodes found.")

      # Use purrr::walk instead of while/for to comply with APAF Zero-Tolerance Policy
      paused_at <- NULL
      completed <- FALSE

      purrr::walk(seq_len(max_steps), function(step_idx) {
        if (!is.null(paused_at) || completed || step_count >= max_steps) {
          return()
        }
        if (length(current_nodes) == 0) {
          completed <<- TRUE
          return()
        }

        next_queue <- character(0)

        # Parallel Execution Block
        nodes_to_run_parallel <- if (!is.null(self$worktree_manager)) current_nodes else character(0)

        if (length(nodes_to_run_parallel) > 0) {
          cat(sprintf("[Parallel] Executing %d nodes in isolated worktrees using furrr...\n", length(nodes_to_run_parallel)))
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
            self$results[[node_id]] <<- res
            if (!is.null(res$output)) {
              if (is_named_list(res$output)) self$state$update(res$output) else self$state$update(setNames(list(res$output), node_id))
            }
            step_count <<- step_count + 1
            self$trace_log[[step_count]] <<- list(
              step = step_count, node = node_id, mode = "parallel",
              start_time = as.character(p_res$start), end_time = as.character(p_res$end),
              duration_secs = as.numeric(difftime(p_res$end, p_res$start, units = "secs")),
              status = res$status,
              error = if (!is.null(res$error)) as.character(res$error) else if (res$status == "failed" && !is.null(p_res$error)) as.character(p_res$error) else NULL
            )
            if (!is.null(res$status) && tolower(res$status) == "pause") {
              paused_at <<- node_id
              completed <<- TRUE
            }

            # Successors Logic (Unified Routing)
            target <- NULL

            # 1. Error Edge (Highest priority if failed)
            if (!is.null(res$status) && res$status %in% c("failed", "error") && node_id %in% names(self$error_edges)) {
              cat(sprintf("   [%s] Node failed (Parallel). Following error edge to: %s\n", node_id, self$error_edges[[node_id]]))
              target <- self$error_edges[[node_id]]
            }
            # 2. Dynamic Router Output
            else if (!is.null(res$target_node)) {
              cat(sprintf("   [%s] Router (Parallel) selected next node: %s\n", node_id, res$target_node))
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
                next_queue <<- unique(c(next_queue, children))
              }
            }

            if (!is.null(target)) {
              next_queue <<- unique(c(next_queue, target))
            }
          })
        } else {
          # Sequential Execution Block - Using purrr::walk instead of for()
          purrr::walk(current_nodes, function(node_id) {
            if (!is.null(paused_at)) {
              return()
            }
            step_idx_inner <- step_count + 1
            if (step_idx_inner > max_steps) {
              return()
            }

            cat(sprintf("[DEBUG] Queue: %s | Running: %s\n", paste(current_nodes, collapse = ", "), node_id))
            restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)
            start_time <- Sys.time()
            run_call <- list(state = restricted_state)
            run_call <- utils::modifyList(run_call, self$.__enclos_env__$private$.run_args %||% list())
            res <- do.call(self$nodes[[node_id]]$run, run_call)
            end_time <- Sys.time()

            self$results[[node_id]] <<- res
            if (!is.null(res$output)) {
              if (is_named_list(res$output)) self$state$update(res$output) else self$state$update(setNames(list(res$output), node_id))
            }
            self$trace_log[[step_idx_inner]] <<- list(
              step = step_idx_inner, node = node_id, mode = "iterative",
              start_time = as.character(start_time), end_time = as.character(end_time),
              duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
              status = res$status, error = res$error
            )
            step_count <<- step_idx_inner

            if (!is.null(res$status) && tolower(res$status) == "pause") {
              paused_at <<- node_id
              completed <<- TRUE
              next_queue <<- character(0) # Clear the queue to ensure we stop immediately
              return()
            }
            if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

            # Successors Logic (Unified Routing)
            target <- NULL

            # 1. Error Edge (Highest priority if failed)
            if (!is.null(res$status) && res$status %in% c("failed", "error") && node_id %in% names(self$error_edges)) {
              cat(sprintf("   [%s] Node failed. Following error edge to: %s\n", node_id, self$error_edges[[node_id]]))
              target <- self$error_edges[[node_id]]
            }
            # 2. Dynamic Router Output
            else if (!is.null(res$target_node)) {
              cat(sprintf("   [%s] Router selected next node: %s\n", node_id, res$target_node))
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
                next_queue <<- unique(c(next_queue, children))
              }
            }

            if (!is.null(target)) {
              next_queue <<- unique(c(next_queue, target))
            }
          })
        }

        current_nodes <<- next_queue
      })

      if (step_count >= max_steps) warning("Reached max_steps.")
      self$trace_log <- self$trace_log[seq_len(step_count)]
      self$state$set("__next_nodes__", if (length(current_nodes) > 0) current_nodes else NULL)
      if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
      return(list(results = self$results, state = self$state, status = if (!is.null(paused_at) || length(current_nodes) > 0) "paused" else "completed", paused_at = paused_at))
    },

    #' @param type String. Type of plot (currently only "mermaid").
    #' @param status Logical. If TRUE, styling is applied to nodes/edges based on results.
    #' @param details Logical. If TRUE, node parameters are serialized into labels.
    #' @param include_params Character vector. Optional whitelist of parameters to show.
    #' @param show_edge_labels Logical. Whether to show labels on edges.
    #' @return The mermaid string (invisibly).
    plot = function(type = "mermaid", status = FALSE, details = FALSE, include_params = NULL, show_edge_labels = TRUE) {
      if (type != "mermaid") stop("Only 'mermaid' type is currently supported.")

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
            # Special case for consensus results
            lbl <- paste(lbl, sprintf("[%s]", out_val$final_consensus), sep = " ")
          }
        }

        if (details && length(node$params) > 0) {
          # Filter params if needed
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

        sprintf("  %s[\"%s\"]", node_id, lbl)
      })

      # 2. Collect All Possible Edges (for consistent indexing)
      all_edges_list <- list()

      # Standard edges
      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) do.call(rbind, self$edges) else self$edges
      if (!is.null(edges_df) && nrow(edges_df) > 0) {
        purrr::walk(seq_len(nrow(edges_df)), function(i) {
          lbl <- if (is.na(edges_df$label[i])) NULL else edges_df$label[i]
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = edges_df$from[i], to = edges_df$to[i], label = lbl)
        })
      }

      # Conditional edges
      # We sort keys to ensure deterministic ordering of indices
      sorted_cond_from <- sort(names(self$conditional_edges))
      purrr::walk(sorted_cond_from, function(from) {
        cond <- self$conditional_edges[[from]]
        if (!is.null(cond$if_true)) {
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = from, to = cond$if_true, label = "Test", type = "cond")
        }
        if (!is.null(cond$if_false)) {
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = from, to = cond$if_false, label = "Fail", type = "cond")
        }
      })

      # Error edges
      sorted_err_from <- sort(names(self$error_edges))
      purrr::walk(sorted_err_from, function(from) {
        target <- self$error_edges[[from]]
        all_edges_list[[length(all_edges_list) + 1]] <<- list(from = from, to = target, label = "error", type = "error")
      })

      # Generate edge lines
      edge_lines <- purrr::map_chr(all_edges_list, function(e) {
        if (show_edge_labels && !is.null(e$label)) {
          sprintf("  %s -- %s --> %s", e$from, e$label, e$to)
        } else {
          sprintf("  %s --> %s", e$from, e$to)
        }
      })

      extra_lines <- character()
      if (status && length(self$results) > 0) {
        # Class Definitions
        extra_lines <- c(
          "  classDef success fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;",
          "  classDef failure fill:#ff8a80,stroke:#b71c1c,stroke-width:2px;",
          "  classDef active fill:#bbdefb,stroke:#0d47a1,stroke-width:2px;",
          "  classDef pause fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;"
        )

        # Node styling
        purrr::iwalk(self$results, function(res, node_id) {
          status_val <- res$status %||% ""
          cls <- if (identical(status_val, "success")) "success" else if (status_val %in% c("failed", "error")) "failure" else if (identical(status_val, "pause")) "pause" else NULL
          if (!is.null(cls)) extra_lines <<- c(extra_lines, sprintf("  class %s %s", node_id, cls))
        })

        # Edge highlighting (linkStyle)
        # Identify traversed pairs from trace_log
        if (length(self$trace_log) > 0) {
          executed_nodes <- purrr::map_chr(purrr::compact(self$trace_log), ~ .x$node)

          purrr::iwalk(all_edges_list, function(e, idx) {
            # Highlight if it's an error edge (RED)
            if (identical(e$type, "error")) {
              extra_lines <<- c(extra_lines, sprintf("  linkStyle %d stroke:#e53935,stroke-width:2px,stroke-dasharray: 5 5;", idx - 1))
            }

            # Highlight as TRAVERSED (Success sequence)
            if (e$from %in% executed_nodes && e$to %in% executed_nodes) {
              # If it's a successful error path, we still make it green but keep it dashed maybe?
              # For now, just follow execution path
              color <- if (identical(e$type, "error")) "#e53935" else "#388e3c"
              extra_lines <<- c(extra_lines, sprintf("  linkStyle %d stroke:%s,stroke-width:4px;", idx - 1, color))
            }
          })
        } else {
          # Even without results, style the error edges as red/dashed
          purrr::iwalk(all_edges_list, function(e, idx) {
            if (identical(e$type, "error")) {
              extra_lines <<- c(extra_lines, sprintf("  linkStyle %d stroke:#e53935,stroke-width:2px,stroke-dasharray: 5 5;", idx - 1))
            }
          })
        }
      }

      lines <- c("```mermaid", "graph TD", node_lines, edge_lines, extra_lines, "```")
      res <- paste(lines, collapse = "\n")
      cat(res, "\n")
      return(invisible(res))
    },

    #' Get Terminal Nodes
    #' @description Identifies nodes with no outgoing edges.
    #' @return Character vector of node IDs.
    get_terminal_nodes = function() {
      private$.rebuild_graph()
      names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "out") == 0])
    },

    #' Get Start Nodes (Roots)
    #' @description Identifies nodes with no incoming edges.
    #' @return Character vector of node IDs.
    get_start_nodes = function() {
      private$.rebuild_graph()
      names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
    },

    #' Compile the Graph
    #' @description
    #' Rebuilds the internal graph representation and performs validation checks.
    #' @return The AgentDAG object (invisibly).
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
        reachable <- igraph::bfs(self$graph, root = self$start_node, unreachable = FALSE)$order
        reachable_names <- names(igraph::V(self$graph)[reachable[!is.na(reachable)]])
        unreachable <- setdiff(names(self$nodes), reachable_names)
        if (length(unreachable) > 0) {
          warning(sprintf("Nodes unreachable from start node '%s': %s", self$start_node, paste(unreachable, collapse = ", ")))
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
    #' @param file String. Output path for the JSON trace.
    save_trace = function(file = "dag_trace.json") {
      jsonlite::write_json(self$trace_log, path = file, pretty = TRUE, auto_unbox = TRUE)
      cat(sprintf("[Saved] Saved execution trace to: %s\n", file))
      invisible(self)
    },

    #' Create Graph from Mermaid
    #' @param mermaid_str String. Mermaid syntax.
    #' @param node_factory Function(id, label, params) -> AgentNode.
    #' @return The AgentDAG object.
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
    .packages = c("withr", "HydraR"),
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

#' Create AgentDAG from Mermaid
#' @param mermaid_str String. Mermaid syntax.
#' @param node_factory Function(id, label) -> AgentNode. Defaults to `auto_node_factory()`.
#' @return The AgentDAG object.
#' @export
mermaid_to_dag <- function(mermaid_str, node_factory = auto_node_factory()) {
  dag <- AgentDAG$new()
  dag$from_mermaid(mermaid_str, node_factory)
  return(dag)
}

#' <!-- APAF Bioinformatics | dag.R | Approved | 2026-03-30 -->

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
#' @export
AgentDAG <- R6::R6Class("AgentDAG",
  public = list(
    #' @field nodes List. Named list of AgentNode objects.
    nodes = list(),
    #' @field edges List. Pending edge definitions to be bound.
    edges = list(),
    #' @field conditional_edges List. Conditional transition logic.
    conditional_edges = list(),
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
    add_edge = function(from, to) {
      if (!is.character(from)) stop("from must be a character vector of node IDs.")
      if (!is.character(to) || length(to) != 1) stop("to must be a single string node ID.")

      new_edges <- data.frame(from = from, to = to, stringsAsFactors = FALSE)
      self$edges[[length(self$edges) + 1]] <- new_edges
      self$graph <- NULL # Invalidate cache
      invisible(self)
    },

    #' Add a Conditional Edge (Loop Support)
    #' @param from String node ID.
    #' @param test Function(output) -> Logical.
    #' @param if_true String node ID (next node if test is TRUE) or NULL to stop.
    #' @param if_false String node ID (next node if test is FALSE) or NULL to stop.
    add_conditional_edge = function(from, test, if_true, if_false = NULL) {
      if (!is.character(from) || length(from) != 1 || !from %in% names(self$nodes)) {
        stop(sprintf("from node '%s' must be an existing node ID string.", from))
      }
      if (!is.function(test)) stop("test must be a function.")

      if (!is.null(if_true)) {
        if (!is.character(if_true) || !if_true %in% names(self$nodes)) {
          stop(sprintf("if_true node '%s' not found in DAG", if_true))
        }
      }

      if (!is.null(if_false)) {
        if (!is.character(if_false) || !if_false %in% names(self$nodes)) {
          stop(sprintf("if_false node '%s' not found in DAG", if_false))
        }
      }

      self$conditional_edges[[from]] <- list(
        test = test,
        if_true = if_true,
        if_false = if_false
      )
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
                   ...) {
      self$compile()
      private$.fail_if_dirty <- fail_if_dirty
      private$.run_args <- list(...)

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
            s <- if (inherits(initial_state, "AgentState")) initial_state else AgentState$new(initial_state)
            purrr::iwalk(loaded_state$get_all(), ~ s$set(.y, .x))
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
        return(self$.run_iterative(max_steps, checkpointer, thread_id, resume_from, fail_if_dirty = fail_if_dirty))
      }

      # Default to linear if pure DAG and no complex features requested
      if (length(self$conditional_edges) == 0 && igraph::is_dag(self$graph)) {
        return(self$.run_linear(max_steps, checkpointer, thread_id, resume_from, fail_if_dirty = fail_if_dirty))
      }

      # Fallback to iterative for cycles and conditional logic
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
          if (is.list(res$output)) {
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
    .run_iterative = function(max_steps, checkpointer = NULL, thread_id = NULL, resume_from = NULL, step_count = 0, fail_if_dirty = TRUE) {
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
            }
            withr::with_dir(wt_path, {
              restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)
              st <- Sys.time()
              # Pass stored arguments via do.call
              run_call <- list(state = restricted_state)
              run_call <- utils::modifyList(run_call, self$.__enclos_env__$private$.run_args)
              res <- do.call(node$run, run_call)
              et <- Sys.time()
              list(id = node_id, res = res, start = st, end = et)
            })
          }, .options = furrr::furrr_options(globals = c("self"), packages = c("withr", "HydraR")))

          # Integrate results and collect next nodes
          purrr::walk(parallel_results, function(p_res) {
            node_id <- p_res$id
            res <- p_res$res
            self$results[[node_id]] <<- res
            if (!is.null(res$output)) {
              if (is.list(res$output)) self$state$update(res$output) else self$state$update(setNames(list(res$output), node_id))
            }
            step_count <<- step_count + 1
            self$trace_log[[step_count]] <<- list(
              step = step_count, node = node_id, mode = "parallel",
              start_time = as.character(p_res$start), end_time = as.character(p_res$end),
              duration_secs = as.numeric(difftime(p_res$end, p_res$start, units = "secs")),
              status = res$status, error = res$error
            )
            # if (!is.null(self$worktree_manager)) self$worktree_manager$remove_worktree(node_id)
            if (!is.null(res$status) && tolower(res$status) == "pause") {
              paused_at <<- node_id
              completed <<- TRUE
            }

            # Successors
            if (node_id %in% names(self$conditional_edges)) {
              cond <- self$conditional_edges[[node_id]]
              test_passed <- tryCatch(cond$test(res$output), error = function(e) FALSE)
              target <- if (test_passed) cond$if_true else cond$if_false
              if (!is.null(target)) next_queue <<- unique(c(next_queue, target))
            } else {
              children <- names(igraph::adjacent_vertices(self$graph, node_id, mode = "out")[[1]])
              next_queue <<- unique(c(next_queue, children))
            }
          })
          
          # UPDATE QUEUE FOR NEXT STEP
          queue <- unique(next_queue)
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

            cat(sprintf("[Iteration %d] Running Node: %s\n", step_idx_inner, node_id))
            restricted_state <- RestrictedState$new(self$state, node_id, self$message_log)
            start_time <- Sys.time()
            res <- self$nodes[[node_id]]$run(restricted_state)
            end_time <- Sys.time()

            self$results[[node_id]] <<- res
            if (!is.null(res$output)) {
              if (is.list(res$output)) self$state$update(res$output) else self$state$update(setNames(list(res$output), node_id))
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

            # Successors
            if (node_id %in% names(self$conditional_edges)) {
              cond <- self$conditional_edges[[node_id]]
              test_passed <- tryCatch(cond$test(res$output), error = function(e) FALSE)
              target <- if (test_passed) cond$if_true else cond$if_false
              if (!is.null(target)) next_queue <<- unique(c(next_queue, target))
            } else {
              children <- names(igraph::adjacent_vertices(self$graph, node_id, mode = "out")[[1]])
              next_queue <<- unique(c(next_queue, children))
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

    #' Plot the DAG
    #' @param type String. Currently only "mermaid" is supported.
    #' @param status Logical. If TRUE, styling is applied to nodes/edges based on results.
    #' @return The mermaid string (invisibly).
    plot = function(type = "mermaid", status = FALSE) {
      if (type != "mermaid") stop("Only 'mermaid' type is currently supported.")

      # 1. Define Nodes
      node_lines <- purrr::map_chr(names(self$nodes), function(node_id) {
        node <- self$nodes[[node_id]]
        sprintf("  %s[\"%s\"]", node_id, node$label)
      })

      # 2. Collect All Possible Edges (for consistent indexing)
      all_edges_list <- list()
      
      # Standard edges
      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) do.call(rbind, self$edges) else self$edges
      if (!is.null(edges_df) && nrow(edges_df) > 0) {
        purrr::walk(seq_len(nrow(edges_df)), function(i) {
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = edges_df$from[i], to = edges_df$to[i], label = NULL)
        })
      }
      
      # Conditional edges
      # We sort keys to ensure deterministic ordering of indices
      sorted_cond_from <- sort(names(self$conditional_edges))
      purrr::walk(sorted_cond_from, function(from) {
        cond <- self$conditional_edges[[from]]
        if (!is.null(cond$if_true)) {
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = from, to = cond$if_true, label = "Test")
        }
        if (!is.null(cond$if_false)) {
          all_edges_list[[length(all_edges_list) + 1]] <<- list(from = from, to = cond$if_false, label = "Fail")
        }
      })

      # Generate edge lines
      edge_lines <- purrr::map_chr(all_edges_list, function(e) {
        if (!is.null(e$label)) {
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
          cls <- if (res$status == "success") "success" else if (res$status %in% c("failed", "error")) "failure" else if (res$status == "pause") "pause" else NULL
          if (!is.null(cls)) extra_lines <<- c(extra_lines, sprintf("  class %s %s", node_id, cls))
        })

        # Edge highlighting (linkStyle)
        # Identify traversed pairs from trace_log
        if (length(self$trace_log) > 1) {
          traversed_nodes <- purrr::map_chr(purrr::compact(self$trace_log), ~ .x$node)
          traversed_pairs <- purrr::map(seq_len(length(traversed_nodes) - 1), function(i) {
            paste(traversed_nodes[i], traversed_nodes[i + 1], sep = "->")
          }) |> unlist() |> unique()

          # Find indices in all_edges_list
          purrr::iwalk(all_edges_list, function(e, idx) {
            pair_key <- paste(e$from, e$to, sep = "->")
            if (pair_key %in% traversed_pairs) {
              # linkStyle is 0-indexed
              extra_lines <<- c(extra_lines, sprintf("  linkStyle %d stroke:#388e3c,stroke-width:4px;", idx - 1))
            }
          })
        }
      }

      lines <- c("```mermaid", "graph TD", node_lines, edge_lines, extra_lines, "```")
      res <- paste(lines, collapse = "\n")
      cat(res, "\n")
      invisible(res)
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
          warning("The graph contains cycles and no conditional edges are defined. Linear execution may fail.")
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

    #' Create AgentDAG from Mermaid
    #' @param mermaid_str String. Mermaid syntax.
    #' @param node_factory Function(id, label) -> AgentNode.
    #' @return The AgentDAG object.
    from_mermaid = function(mermaid_str, node_factory) {
      stopifnot(is.function(node_factory))
      parsed <- parse_mermaid(mermaid_str)

      # Add nodes
      purrr::walk(seq_len(nrow(parsed$nodes)), function(i) {
        id <- parsed$nodes$id[i]
        label <- parsed$nodes$label[i]
        node <- node_factory(id, label)
        if (!is.null(node)) {
          self$add_node(node)
        }
      })

      # Add edges
      purrr::walk(seq_len(nrow(parsed$edges)), function(i) {
        from <- parsed$edges$from[i]
        to <- parsed$edges$to[i]
        label <- parsed$edges$label[i]

        # Check if it's a conditional edge
        # Convention: if label starts with "test:" or it matches a known conditional pattern
        if (nzchar(label) && grepl("^test:", label)) {
          # This is simplified: we need a way to get the actual function
          # Maybe node_factory can also return test functions?
          # For now, let's just add it as a normal edge and warn
          warning(sprintf("Conditional edge from '%s' to '%s' with label '%s' detected but logic mapping is not yet implemented.", from, to, label))
          self$add_edge(from, to)
        } else {
          self$add_edge(from, to)
        }
      })

      invisible(self)
    }
  ),
  private = list(
    .fail_if_dirty = TRUE,
    .run_args = list(),
    .rebuild_graph = function() {
      if (!is.null(self$graph)) {
        return(invisible(self))
      } # Cache hit

      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) {
        do.call(rbind, self$edges)
      } else if (is.data.frame(self$edges)) {
        self$edges
      } else {
        data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
      }

      # Incorporate Conditional Edges into the graph for analysis
      if (length(self$conditional_edges) > 0) {
        cond_edges <- purrr::imap(self$conditional_edges, function(cond, from) {
          df_list <- list()
          if (!is.null(cond$if_true)) {
            df_list[[length(df_list) + 1]] <- data.frame(from = from, to = cond$if_true, stringsAsFactors = FALSE)
          }
          if (!is.null(cond$if_false)) {
            df_list[[length(df_list) + 1]] <- data.frame(from = from, to = cond$if_false, stringsAsFactors = FALSE)
          }
          if (length(df_list) == 0) return(NULL)
          do.call(rbind, df_list)
        }) |> purrr::compact() |> purrr::list_rbind()
        
        if (!is.null(cond_edges) && nrow(cond_edges) > 0) {
          edges_df <- rbind(edges_df, cond_edges)
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
#' @param node_factory Function(id, label) -> AgentNode.
#' @return The AgentDAG object.
#' @export
mermaid_to_dag <- function(mermaid_str, node_factory) {
  dag <- AgentDAG$new()
  dag$from_mermaid(mermaid_str, node_factory)
  return(dag)
}

#' <!-- APAF Bioinformatics | dag.R | Approved | 2026-03-29 -->

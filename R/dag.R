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
#' @importFrom R6 R6Class
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
    },

    #' Set Start Node
    #' @param node_id String node ID.
    set_start_node = function(node_id) {
      stopifnot(is.character(node_id) && node_id %in% names(self$nodes))
      self$start_node <- node_id
      invisible(self)
    },

    #' Add a Node
    #' @param node AgentNode object.
    add_node = function(node) {
      stopifnot(inherits(node, "AgentNode"))
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
      stopifnot(is.character(from) && is.character(to))
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
      stopifnot(is.character(from) && from %in% names(self$nodes))
      stopifnot(is.function(test))

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
    #' @return List of results for each node, and the final state.
    run = function(initial_state = NULL, max_steps = 25, checkpointer = NULL, thread_id = NULL, resume_from = NULL) {
      self$compile()

      # Preallocation of results and trace log
      # For linear execution, we know the exact number of nodes.
      # For iterative, we use max_steps as the upper bound.
      self$results <- vector("list", length(self$nodes))
      names(self$results) <- names(self$nodes)

      self$trace_log <- vector("list", max_steps)

      if (!is.null(checkpointer)) {
        stopifnot(inherits(checkpointer, "Checkpointer"))
        if (is.null(thread_id)) stop("thread_id must be provided when using a checkpointer.")

        # Try to load state from checkpointer
        loaded_state <- checkpointer$get(thread_id)
        if (!is.null(loaded_state)) {
          cat(sprintf("[Iteration] Restored state from checkpoint for thread: %s\n", thread_id))

          if (is.null(initial_state)) {
            self$state <- loaded_state
          } else {
            # Merge restored data into the provided initial state configuration
            if (inherits(initial_state, "AgentState")) {
              self$state <- initial_state
              restored_data <- loaded_state$get_all()
              purrr::iwalk(restored_data, function(val, k) {
                self$state$set(k, val)
              })
            } else {
              self$state <- AgentState$new(initial_state)
              restored_data <- loaded_state$get_all()
              purrr::iwalk(restored_data, function(val, k) {
                self$state$set(k, val)
              })
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

      # Check for auto-resume
      auto_resume_nodes <- self$state$get("__next_nodes__")
      if (is.null(resume_from) && !is.null(auto_resume_nodes)) {
        resume_from <- auto_resume_nodes
      }

      if (length(self$conditional_edges) == 0 && igraph::is_dag(self$graph)) {
        return(self$.run_linear(checkpointer, thread_id, resume_from))
      }

      return(self$.run_iterative(max_steps, checkpointer, thread_id, resume_from))
    },

    #' Internal: Linear DAG Execution
    #' @param checkpointer Checkpointer object.
    #' @param thread_id String thread ID.
    #' @param resume_from Node ID(s) to resume from.
    #' @param node_ids Character vector of nodes to run.
    #' @param depth Integer current recursion depth.
    #' @param step_count Integer current total step count.
    #' @return Execution result list.
    .run_linear = function(checkpointer = NULL, thread_id = NULL, resume_from = NULL, node_ids = NULL, depth = 0, step_count = 0) {
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

      if (length(node_ids) == 0) {
        # Trim unused preallocated trace log slots
        if (step_count < length(self$trace_log)) {
          self$trace_log <- self$trace_log[seq_len(step_count)]
        }
        self$state$set("__next_nodes__", NULL)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "completed"))
      }

      if (depth >= 100 || (step_count + 1) > length(self$trace_log)) {
        reason <- if (depth >= 100) "recursion_limit" else "max_steps_limit"
        warning(sprintf("Execution limit reached in .run_linear for thread: %s. Saving state for restart.", thread_id %||% "unknown"))

        # Trim trace log
        self$trace_log <- self$trace_log[seq_len(step_count)]

        self$state$set("__next_nodes__", node_ids)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = node_ids[1], reason = reason))
      }

      node_id <- node_ids[1]
      cat(sprintf("[Linear] Running Node: %s\n", node_id))
      start_time <- Sys.time()
      res <- self$nodes[[node_id]]$run(self$state)
      end_time <- Sys.time()

      self$results[[node_id]] <- res

      if (!is.null(res$output)) {
        if (is.list(res$output)) {
          self$state$update(res$output)
        } else {
          self$state$update(setNames(list(res$output), node_id))
        }
      }

      step_idx <- step_count + 1
      self$trace_log[[step_idx]] <- list(
        step = step_idx,
        node = node_id,
        mode = "linear",
        start_time = as.character(start_time),
        end_time = as.character(end_time),
        duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
        status = res$status,
        error = res$error
      )

      if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)

      if (!is.null(res$status) && res$status == "pause") {
        # Trim trace log
        self$trace_log <- self$trace_log[seq_len(step_idx)]
        self$state$set("__next_nodes__", node_ids[-1])
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = node_id))
      }

      return(self$.run_linear(checkpointer, thread_id, NULL, node_ids[-1], depth + 1, step_idx))
    },

    #' Internal: Iterative State Machine Execution
    #' @param max_steps Integer.
    #' @param checkpointer Checkpointer.
    #' @param thread_id String.
    #' @param resume_from String.
    #' @param current_nodes Character vector.
    #' @param step_count Integer.
    #' @param depth Integer. Current recursion depth.
    .run_iterative = function(max_steps, checkpointer = NULL, thread_id = NULL, resume_from = NULL, current_nodes = NULL, step_count = 0, depth = 0) {
      if (is.null(current_nodes)) {
        if (!is.null(resume_from)) {
          current_nodes <- resume_from
          cat(sprintf("[Resuming] Resuming Iterative DAG Execution from node(s): %s\n", paste(resume_from, collapse = ", ")))
        } else {
          current_nodes <- if (!is.null(self$start_node)) {
            self$start_node
          } else {
            names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
          }
          if (length(current_nodes) == 0) stop("No start nodes found.")
        }
      }

      if (length(current_nodes) == 0 || step_count >= max_steps) {
        if (step_count >= max_steps) warning("Reached max_steps.")
        # Trim trace log
        if (step_count < length(self$trace_log)) {
          self$trace_log <- self$trace_log[seq_len(step_count)]
        }
        self$state$set("__next_nodes__", NULL)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "completed"))
      }

      if (depth >= 100) {
        warning(sprintf("Recursion limit (100) reached in .run_iterative for thread: %s. Saving state for restart.", thread_id %||% "unknown"))
        # Trim trace log
        self$trace_log <- self$trace_log[seq_len(step_count)]
        self$state$set("__next_nodes__", current_nodes)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = current_nodes[1], reason = "recursion_limit"))
      }

      # Preallocate space for potential children (max out-degree approximation or dynamic growth)
      # Since iterative step nodes can be multiple, we collect them.
      next_queue_list <- vector("list", length(current_nodes))
      paused_at <- NULL
      actual_steps_in_this_recursion <- 0

      # Using imap to track index for preallocation assignment if needed,
      # but trace_log is sequential across recursive calls.
      purrr::walk(current_nodes, function(node_id) {
        if (!is.null(paused_at)) {
          return()
        }

        step_idx <- step_count + actual_steps_in_this_recursion + 1
        if (step_idx > length(self$trace_log)) {
          return()
        } # Safety check

        cat(sprintf("[Iteration %d] Running Node: %s\n", step_idx, node_id))
        start_time <- Sys.time()
        res <- self$nodes[[node_id]]$run(self$state)
        end_time <- Sys.time()

        self$results[[node_id]] <- res

        if (!is.null(res$output)) {
          if (is.list(res$output)) {
            self$state$update(res$output)
          } else {
            self$state$update(setNames(list(res$output), node_id))
          }
        }

        self$trace_log[[step_idx]] <- list(
          step = step_idx,
          node = node_id,
          mode = "iterative",
          start_time = as.character(start_time),
          end_time = as.character(end_time),
          duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
          status = res$status,
          error = res$error
        )
        actual_steps_in_this_recursion <<- actual_steps_in_this_recursion + 1

        if (node_id %in% names(self$conditional_edges)) {
          cond <- self$conditional_edges[[node_id]]
          test_passed <- tryCatch(cond$test(res$output), error = function(e) FALSE)
          target <- if (test_passed) cond$if_true else cond$if_false
          if (!is.null(target)) {
            next_queue_list[[match(node_id, current_nodes)]] <<- list(target)
          }
        } else {
          children <- names(igraph::adjacent_vertices(self$graph, node_id, mode = "out")[[1]])
          if (length(children) > 0) {
            next_queue_list[[match(node_id, current_nodes)]] <<- as.list(children)
          }
        }

        if (!is.null(res$status) && res$status == "pause") {
          paused_at <<- node_id
        }

        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
      })

      # Flatten next_queue_list
      next_queue <- unique(unlist(next_queue_list))
      if (is.null(next_queue)) next_queue <- character(0)

      if (!is.null(paused_at)) {
        self$trace_log <- self$trace_log[seq_len(step_count + actual_steps_in_this_recursion)]
        self$state$set("__next_nodes__", next_queue)
        if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
        return(list(results = self$results, state = self$state, status = "paused", paused_at = paused_at))
      }

      return(self$.run_iterative(max_steps, checkpointer, thread_id, NULL, next_queue, step_count + actual_steps_in_this_recursion, depth + 1))
    },

    #' Plot the DAG
    #' @param type String. Currently only "mermaid" is supported.
    #' @return The mermaid string (invisibly).
    plot = function(type = "mermaid") {
      if (type != "mermaid") stop("Only 'mermaid' type is currently supported.")

      # Use preallocated character vector for lines
      node_lines <- purrr::map_chr(names(self$nodes), function(node_id) {
        node <- self$nodes[[node_id]]
        sprintf("  %s[\"%s\"]", node_id, node$label)
      })

      # Efficient edge gathering
      edges_df <- if (is.list(self$edges) && length(self$edges) > 0) do.call(rbind, self$edges) else self$edges
      edge_lines <- if (!is.null(edges_df) && nrow(edges_df) > 0) {
        purrr::map_chr(seq_len(nrow(edges_df)), function(i) {
          sprintf("  %s --> %s", edges_df$from[i], edges_df$to[i])
        })
      } else {
        character()
      }

      # Conditional edges
      cond_lines <- purrr::imap(self$conditional_edges, function(cond, from) {
        res <- sprintf("  %s -- Test --> %s", from, cond$if_true)
        if (!is.null(cond$if_false)) {
          res <- c(res, sprintf("  %s -- Fail --> %s", from, cond$if_false))
        }
        res
      }) |> unlist()

      lines <- c("```mermaid", "graph TD", node_lines, edge_lines, cond_lines, "```")
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

#' <!-- APAF Bioinformatics | dag.R | Approved | 2026-03-28 -->

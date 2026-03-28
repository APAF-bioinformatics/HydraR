#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        dag.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Multi-Agent Graph Orchestrator (DAG + Loops)
#' Constraint:  Hardness-Oriented Development, Parallel Execution (furrr)
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Agent Graph R6 Class
#'
#' @description
#' Defines and executes a Directed Graph of AgentNodes.
#' Supports both pure DAG execution (parallel) and iterative loops via conditional edges.
#'
#' @importFrom R6 R6Class
#' @importFrom igraph graph_from_data_frame is_dag topo_sort edge V vcount make_empty_graph degree is_connected components bfs
#' @importFrom furrr future_map
#' @importFrom purrr map set_names
#' @export
AgentDAG <- R6::R6Class("AgentDAG",
    public = list(
        #' @field nodes List. Named list of AgentNode objects.
        nodes = list(),
        #' @field edges Dataframe. Edge definitions (from, to).
        edges = NULL,
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
            self$edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
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
            self$edges <- rbind(self$edges, new_edges)
            self$.rebuild_graph()
            invisible(self)
        },

        #' Add a Conditional Edge (Loop Support)
        #' @param from String node ID.
        #' @param test Function(output) -> Logical.
        #' @param if_true String node ID (next node if test is TRUE).
        #' @param if_false String node ID (next node if test is FALSE or NULL for end).
        add_conditional_edge = function(from, test, if_true, if_false = NULL) {
            stopifnot(is.character(from) && from %in% names(self$nodes))
            stopifnot(is.function(test))
            stopifnot(is.character(if_true) && if_true %in% names(self$nodes))
            if (!is.null(if_false)) stopifnot(is.character(if_false) && if_false %in% names(self$nodes))
            
            self$conditional_edges[[from]] <- list(
                test = test,
                if_true = if_true,
                if_false = if_false
            )
            invisible(self)
        },

        #' Run the Graph
        #' @param initial_state List, AgentState object, or String. Optional if resuming.
        #' @param max_steps Integer. Maximum iterations to prevent infinite loops.
        #' @param checkpointer Checkpointer object. Optional.
        #' @param thread_id String. Identifier for the execution thread. Required if using checkpointer.
        #' @param resume_from String. Node ID to resume execution from.
        #' @return List of results for each node, and the final state.
        run = function(initial_state = NULL, max_steps = 10, checkpointer = NULL, thread_id = NULL, resume_from = NULL) {
            self$.rebuild_graph()
            self$results <- list()
            self$trace_log <- list()

            if (!is.null(checkpointer)) {
                stopifnot(inherits(checkpointer, "Checkpointer"))
                if (is.null(thread_id)) stop("thread_id must be provided when using a checkpointer.")

                # Try to load state from checkpointer
                loaded_state <- checkpointer$get(thread_id)
                if (!is.null(loaded_state)) {
                    cat(sprintf("🔄 Restored state from checkpoint for thread: %s\n", thread_id))

                    if (is.null(initial_state)) {
                        self$state <- loaded_state
                    } else {
                        # Merge restored data into the provided initial state configuration
                        if (inherits(initial_state, "AgentState")) {
                            self$state <- initial_state
                            restored_data <- loaded_state$get_all()
                            for (k in names(restored_data)) {
                                self$state$set(k, restored_data[[k]])
                            }
                        } else {
                             self$state <- AgentState$new(initial_state)
                             restored_data <- loaded_state$get_all()
                             for (k in names(restored_data)) {
                                 self$state$set(k, restored_data[[k]])
                             }
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
        #' @param checkpointer Checkpointer.
        #' @param thread_id String.
        #' @param resume_from String.
        .run_linear = function(checkpointer = NULL, thread_id = NULL, resume_from = NULL) {
            topo_order <- igraph::topo_sort(self$graph)
            node_ids <- names(igraph::V(self$graph)[topo_order])

            if (!is.null(resume_from)) {
                resume_idx <- match(resume_from[1], node_ids)
                if (!is.na(resume_idx)) {
                     node_ids <- node_ids[resume_idx:length(node_ids)]
                     cat(sprintf("⏭️ Resuming Linear DAG Execution from node: %s\n", resume_from[1]))
                }
            }

            for (node_id in node_ids) {
                cat(sprintf("🚀 [Linear] Running Node: %s\n", node_id))
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

                self$trace_log[[length(self$trace_log) + 1]] <- list(
                    step = length(self$trace_log) + 1,
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
                     idx <- match(node_id, node_ids)
                     next_nodes <- if (idx < length(node_ids)) node_ids[idx+1] else NULL
                     self$state$set("__next_nodes__", next_nodes)
                     if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
                     return(list(results = self$results, state = self$state, status = "paused", paused_at = node_id))
                }
            }
            self$state$set("__next_nodes__", NULL)
            if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
            return(list(results = self$results, state = self$state, status = "completed"))
        },

        #' Internal: Iterative State Machine Execution
        #' @param max_steps Integer.
        #' @param checkpointer Checkpointer.
        #' @param thread_id String.
        #' @param resume_from String.
        .run_iterative = function(max_steps, checkpointer = NULL, thread_id = NULL, resume_from = NULL) {
            if (!is.null(resume_from)) {
                start_nodes <- resume_from
                cat(sprintf("⏭️ Resuming Iterative DAG Execution from node(s): %s\n", paste(resume_from, collapse = ", ")))
            } else {
                start_nodes <- if (!is.null(self$start_node)) {
                    self$start_node
                } else {
                    names(igraph::V(self$graph)[igraph::degree(self$graph, mode = "in") == 0])
                }
                if (length(start_nodes) == 0) stop("No start nodes found.")
            }
            
            current_nodes <- start_nodes
            step_count <- 0
            
            while (length(current_nodes) > 0 && step_count < max_steps) {
                step_count <- step_count + 1
                next_queue <- character()
                
                for (node_id in current_nodes) {
                    cat(sprintf("🔄 [Iteration %d] Running Node: %s\n", step_count, node_id))
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

                    self$trace_log[[length(self$trace_log) + 1]] <- list(
                        step = step_count,
                        node = node_id,
                        mode = "iterative",
                        start_time = as.character(start_time),
                        end_time = as.character(end_time),
                        duration_secs = as.numeric(difftime(end_time, start_time, units = "secs")),
                        status = res$status,
                        error = res$error
                    )

                    if (node_id %in% names(self$conditional_edges)) {
                        cond <- self$conditional_edges[[node_id]]
                        test_passed <- tryCatch(cond$test(res$output), error = function(e) FALSE)
                        target <- if (test_passed) cond$if_true else cond$if_false
                        if (!is.null(target)) next_queue <- c(next_queue, target)
                    } else {
                        children <- self$edges$to[self$edges$from == node_id]
                        next_queue <- c(next_queue, children)
                    }

                    if (!is.null(res$status) && res$status == "pause") {
                         self$state$set("__next_nodes__", unique(next_queue))
                         if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
                         return(list(results = self$results, state = self$state, status = "paused", paused_at = node_id))
                    }

                    if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
                }
                current_nodes <- unique(next_queue)
            }
            
            if (step_count >= max_steps) warning("Reached max_steps.")
            self$state$set("__next_nodes__", NULL)
            if (!is.null(checkpointer)) checkpointer$put(thread_id, self$state)
            return(list(results = self$results, state = self$state, status = "completed"))
        },

        .rebuild_graph = function() {
            if (nrow(self$edges) > 0) {
                self$graph <- igraph::graph_from_data_frame(self$edges, directed = TRUE, vertices = data.frame(name = names(self$nodes)))
            } else {
                self$graph <- igraph::make_empty_graph(n = length(self$nodes), directed = TRUE)
                igraph::V(self$graph)$name <- names(self$nodes)
            }
            invisible(self)
        },

        #' Plot the DAG
        #' @param type String. Currently only "mermaid" is supported.
        #' @return The mermaid string (invisibly).
        plot = function(type = "mermaid") {
            if (type != "mermaid") stop("Only 'mermaid' type is currently supported.")
            
            lines <- c("```mermaid", "graph TD")
            
            # Add nodes
            for (node_id in names(self$nodes)) {
                lines <- c(lines, sprintf("  %s[\"%s\"]", node_id, node_id))
            }
            
            # Add edges
            if (nrow(self$edges) > 0) {
                for (i in seq_len(nrow(self$edges))) {
                    lines <- c(lines, sprintf("  %s --> %s", self$edges$from[i], self$edges$to[i]))
                }
            }
            
            # Add conditional edges
            for (from in names(self$conditional_edges)) {
                cond <- self$conditional_edges[[from]]
                lines <- c(lines, sprintf("  %s -- Test --> %s", from, cond$if_true))
                if (!is.null(cond$if_false)) {
                    lines <- c(lines, sprintf("  %s -- Fail --> %s", from, cond$if_false))
                }
            }
            
            lines <- c(lines, "```")
            res <- paste(lines, collapse = "\n")
            cat(res, "\n")
            invisible(res)
        },

        #' Compile Graph
        #' @description Rebuilds the internal igraph representation and performs validation.
        compile = function() {
            self$.rebuild_graph()
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

            cat("✅ Graph compiled successfully.\n")
            invisible(self)
        },

        #' Save the Execution Trace
        #' @param file String. Output path for the JSON trace.
        save_trace = function(file = "dag_trace.json") {
            jsonlite::write_json(self$trace_log, path = file, pretty = TRUE, auto_unbox = TRUE)
            cat(sprintf("💾 Saved execution trace to: %s\n", file))
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
            for (i in seq_len(nrow(parsed$nodes))) {
                id <- parsed$nodes$id[i]
                label <- parsed$nodes$label[i]
                node <- node_factory(id, label)
                if (!is.null(node)) {
                    self$add_node(node)
                }
            }
            
            # Add edges
            for (i in seq_len(nrow(parsed$edges))) {
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
            }
            
            invisible(self)
        }
    )
)

# <!-- APAF Bioinformatics | dag.R | Approved | 2026-03-28 -->

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        factory.R
# Author:      APAF Agentic Workflow
# Purpose:     Helper functions for syntactic sugar to create agent nodes in HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Create an Agent Graph
#' @param message_log MessageLog. Optional audit log for the DAG.
#' @return An AgentDAG object.
#' 
dag_create <- function(message_log = NULL) {
  dag <- AgentDAG$new()
  dag$message_log <- message_log
  return(dag)
}


#' Create an LLM Agent Node easily
#'
#' @param id String. Unique identifier for the node.
#' @param role String. System prompt/role for the agent.
#' @param driver AgentDriver object.
#' @param model String. Optional model override.
#' @param cli_opts List. Optional CLI options.
#' @param ... Additional arguments passed to AgentLLMNode$new()
#' @return AgentLLMNode object.
#' 
add_llm_node <- function(id, role, driver, model = NULL, cli_opts = list(), ...) {
  AgentLLMNode$new(id = id, role = role, driver = driver, model = model, cli_opts = cli_opts, ...)
}

#' Create an R Logic Node easily
#'
#' @param id String. Unique identifier for the node.
#' @param logic_fn Function. Pure R function taking an AgentState object.
#' @param ... Additional arguments passed to AgentLogicNode$new()
#' @return AgentLogicNode object.
#' 
add_logic_node <- function(id, logic_fn, ...) {
  AgentLogicNode$new(id = id, logic_fn = logic_fn, ...)
}

#' Add an LLM Agent Node directly to a DAG
#'
#' @param dag AgentDAG object.
#' @param id String. Unique identifier for the node.
#' @param role String. System prompt/role for the agent.
#' @param driver AgentDriver object.
#' @param model String. Optional model override.
#' @param cli_opts List. Optional CLI options.
#' @param ... Additional arguments passed to AgentLLMNode$new()
#' @return The modified AgentDAG object (invisibly).
#' 
dag_add_llm_node <- function(dag, id, role, driver, model = NULL, cli_opts = list(), ...) {
  if (!inherits(dag, "AgentDAG")) {
    stop("dag must be an AgentDAG object.")
  }
  node <- add_llm_node(id = id, role = role, driver = driver, model = model, cli_opts = cli_opts, ...)
  dag$add_node(node)
  invisible(dag)
}

#' Add an R Logic Node directly to a DAG
#'
#' @param dag AgentDAG object.
#' @param id String. Unique identifier for the node.
#' @param logic_fn Function. Pure R function taking an AgentState object.
#' @param ... Additional arguments passed to AgentLogicNode$new()
#' @return The modified AgentDAG object (invisibly).
#' 
dag_add_logic_node <- function(dag, id, logic_fn, ...) {
  if (!inherits(dag, "AgentDAG")) {
    stop("dag must be an AgentDAG object.")
  }
  node <- add_logic_node(id = id, logic_fn = logic_fn, ...)
  dag$add_node(node)
  invisible(dag)
}

#' Standard Node Factory for Mermaid
#'
#' @description
#' Default mapping of Mermaid labels to AgentNodes.
#' Convention: "type:name" or "name"
#' Types supported: "logic", "llm" (requires global driver).
#'
#' @param id String. Node ID.
#' @param label String. Node label.
#' @param driver AgentDriver. Optional driver for LLM nodes.
#' @return AgentNode object.
#' 
standard_node_factory <- function(id, label, driver = NULL) {
  if (grepl("^logic:", label)) {
    fn_name <- gsub("^logic:", "", label)
    # Try to find the function in the environment
    fn <- tryCatch(get(fn_name, mode = "function"), error = function(e) NULL)
    if (is.null(fn)) {
      stop(sprintf("Could not find function '%s' for logic node '%s'.", fn_name, id))
    }
    return(AgentLogicNode$new(id = id, logic_fn = fn))
  } else if (grepl("^llm:", label)) {
    role <- gsub("^llm:", "", label)
    if (is.null(driver)) {
      stop(sprintf("No driver provided for LLM node '%s'.", id))
    }
    return(AgentLLMNode$new(id = id, role = role, driver = driver))
  }

  # Default: Logic node with ID as function name if it exists, else dummy
  fn <- tryCatch(get(label, mode = "function"), error = function(e) NULL)
  if (!is.null(fn)) {
    return(AgentLogicNode$new(id = id, logic_fn = fn))
  }

  # Fallback to dummy
  return(AgentLogicNode$new(id = id, logic_fn = function(state) {
    message(sprintf("Running dummy node '%s' (label: %s)", id, label))
    return(list(output = NULL, status = "ok"))
  }))
}

#' <!-- APAF Bioinformatics | factory.R | Approved | 2026-03-29 -->

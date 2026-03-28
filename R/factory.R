#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        factory.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Helper functions for syntactic sugar to create agent nodes in HydraR
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Create an LLM Agent Node easily
#'
#' @param id String. Unique identifier for the node.
#' @param role String. System prompt/role for the agent.
#' @param driver AgentDriver object.
#' @param ... Additional arguments passed to AgentLLMNode$new()
#' @return AgentLLMNode object.
#' @export
add_llm_node <- function(id, role, driver, ...) {
    AgentLLMNode$new(id = id, role = role, driver = driver, ...)
}

#' Create an R Logic Node easily
#'
#' @param id String. Unique identifier for the node.
#' @param logic_fn Function. Pure R function taking an AgentState object.
#' @param ... Additional arguments passed to AgentLogicNode$new()
#' @return AgentLogicNode object.
#' @export
add_logic_node <- function(id, logic_fn, ...) {
    AgentLogicNode$new(id = id, logic_fn = logic_fn, ...)
}

#' Add an LLM Agent Node directly to a DAG
#'
#' @param dag AgentDAG object.
#' @param id String. Unique identifier for the node.
#' @param role String. System prompt/role for the agent.
#' @param driver AgentDriver object.
#' @param ... Additional arguments passed to AgentLLMNode$new()
#' @return The modified AgentDAG object (invisibly).
#' @export
dag_add_llm_node <- function(dag, id, role, driver, ...) {
    if (!inherits(dag, "AgentDAG")) {
        stop("dag must be an AgentDAG object.")
    }
    node <- add_llm_node(id = id, role = role, driver = driver, ...)
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
#' @export
dag_add_logic_node <- function(dag, id, logic_fn, ...) {
    if (!inherits(dag, "AgentDAG")) {
        stop("dag must be an AgentDAG object.")
    }
    node <- add_logic_node(id = id, logic_fn = logic_fn, ...)
    dag$add_node(node)
    invisible(dag)
}

# <!-- APAF Bioinformatics | factory.R | Approved | 2026-03-29 -->

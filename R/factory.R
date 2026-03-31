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

# ==============================================================
# Global Variable Bindings for R CMD check
# ==============================================================
utils::globalVariables(c(
  "ClaudeCLIDriver", "OpenAIDriver", "GeminiCLIDriver",
  "OllamaDriver", "CopilotCLIDriver"
))

#' <!-- APAF Bioinformatics | factory.R | Approved | 2026-03-30 -->

#' Resolve a Default Driver from Shorthand ID
#'
#' @description
#' Constructs an AgentDriver from a well-known shorthand string like
#' `"gemini"`, `"claude"`, or `"openai"`. Tries the global DriverRegistry
#' first; falls back to constructing a new CLI driver.
#'
#' @param driver_id String. Driver shorthand (e.g., `"gemini"`, `"claude"`).
#' @param driver_registry Optional DriverRegistry object.
#' @return An AgentDriver object.
#' @export
resolve_default_driver <- function(driver_id, driver_registry = NULL) {
  # 1. Try the registry first
  drv_reg <- driver_registry %||% tryCatch(get_driver_registry(), error = function(e) NULL)
  if (!is.null(drv_reg)) {
    registered <- drv_reg$get(driver_id)
    if (!is.null(registered)) {
      return(registered)
    }
  }

  # 2. Auto-construct from shorthand
  switch(driver_id,
    "gemini"  = GeminiCLIDriver$new(),
    "claude"  = ClaudeCodeDriver$new(),
    "openai"  = OpenAIDriver$new(),
    stop(sprintf("Unknown driver shorthand: '%s'. Register it first or use a known ID (gemini, claude, openai).", driver_id))
  )
}

#' Automatic Node Factory for Mermaid-as-Source
#'
#' @description
#' Returns a node factory closure that resolves `type=` annotations
#' directly from Mermaid node parameters. Eliminates the need for
#' hand-written factory functions per workflow.
#'
#' Supported `type=` values:
#' \itemize{
#'   \item `"llm"` -- Creates an \code{AgentLLMNode}. Requires `role` or `role_id`.
#'     Optional: `driver`, `model`, `prompt_id`, `output_format`, `output_path`.
#'   \item `"logic"` -- Creates an \code{AgentLogicNode}. Requires `logic_id`.
#'   \item `"merge"` -- Creates a Merge Harmonizer via \code{create_merge_harmonizer()}.
#'   \item `"auto"` (default if omitted) -- Looks up `id` in the logic registry.
#' }
#'
#' @param driver_registry Optional DriverRegistry object. Defaults to global.
#' @return A function(id, label, params) -> AgentNode.
#'
#' @examples
#' \dontrun{
#' mermaid_src <- '
#' graph TD
#'   A["Researcher | type=llm | role=Research Assistant | driver=gemini"]
#'   B["Validator | type=logic | logic_id=validate_fn"]
#'   A --> B
#' '
#' dag <- AgentDAG$from_mermaid(mermaid_src, node_factory = auto_node_factory())
#' }
#' @export
auto_node_factory <- function(driver_registry = NULL) {
  # Capture registry reference in closure
  drv_reg <- driver_registry

  function(id, label, params) {
    node_type <- params[["type"]] %||% "auto"

    switch(node_type,
      "llm" = {
        # Resolve driver
        driver_id <- params[["driver"]] %||% "gemini"
        driver_obj <- resolve_default_driver(driver_id, driver_registry = drv_reg)

        # Resolve role: inline role= takes precedence, then role_id= lookup
        role <- params[["role"]]
        if (is.null(role) && !is.null(params[["role_id"]])) {
          role <- get_role(params[["role_id"]])
          if (is.null(role)) {
            # Try the logic registry as fallback (some users store roles there)
            role <- get_logic(params[["role_id"]])
          }
        }
        if (is.null(role) || !is.character(role)) {
          stop(sprintf(
            "Node '%s' (type=llm): No role found. Provide 'role=' inline or 'role_id=' referencing a registered role.",
            id
          ))
        }

        # Resolve prompt_builder (optional)
        prompt_builder <- NULL
        if (!is.null(params[["prompt_id"]])) {
          prompt_builder <- get_logic(params[["prompt_id"]])
          if (is.null(prompt_builder)) {
            warning(sprintf("Node '%s': prompt_id '%s' not found in registry. Proceeding without prompt_builder.", id, params[["prompt_id"]]))
          }
        }

        AgentLLMNode$new(
          id = id,
          role = role,
          driver = driver_obj,
          label = label,
          params = params,
          prompt_builder = prompt_builder,
          model = params[["model"]]
        )
      },
      "logic" = {
        logic_id <- params[["logic_id"]]
        if (is.null(logic_id)) {
          stop(sprintf("Node '%s' (type=logic): 'logic_id' parameter is required.", id))
        }
        logic_fn <- get_logic(logic_id)
        if (is.null(logic_fn)) {
          stop(sprintf("Node '%s' (type=logic): logic_id '%s' not found in registry. Register it with register_logic() first.", id, logic_id))
        }
        AgentLogicNode$new(id = id, logic_fn = logic_fn, label = label, params = params)
      },
      "merge" = {
        create_merge_harmonizer(id = id)
      },
      "auto" = {
        # Fallback: try logic registry by id, then passthrough
        fn <- get_logic(id)
        if (!is.null(fn)) {
          return(AgentLogicNode$new(id = id, logic_fn = fn, label = label, params = params))
        }
        # Ultimate fallback: passthrough node
        AgentLogicNode$new(
          id = id,
          logic_fn = function(state) {
            message(sprintf("[auto] Passthrough node '%s' (label: %s)", id, label))
            list(status = "success", output = NULL)
          },
          label = label,
          params = params
        )
      },

      # Unknown type
      stop(sprintf("Node '%s': Unknown type '%s'. Supported: llm, logic, merge, auto.", id, node_type))
    )
  }
}

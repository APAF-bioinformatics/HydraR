# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        factory.R
# Author:      APAF Agentic Workflow
# Purpose:     Helper functions for syntactic sugar to create agent nodes in HydraR
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Create an Agent Graph
#'
#' @description
#' Initializes a new \code{AgentDAG} object. This is the primary entry point for
#' building orchestration workflows either programmatically or from definitions.
#'
#' @param message_log MessageLog.
#' An optional \code{MessageLog} R6 object (e.g., \code{MemoryMessageLog} or
#' \code{DuckDBMessageLog}) used to capture all inter-node communication for
#' auditing and debugging.
#'
#' @return An \code{AgentDAG} R6 object.
#'
#' @examples
#' \dontrun{
#' # Basic DAG creation
#' dag <- dag_create()
#'
#' # Creation with a persistent DuckDB audit log
#' # Recommended for production workflows to ensure audutability.
#' log <- DuckDBMessageLog$new(db_path = "audit_trail.duckdb")
#' dag <- dag_create(message_log = log)
#' }
dag_create <- function(message_log = NULL) {
  dag <- AgentDAG$new()
  dag$message_log <- message_log
  return(dag)
}


#' Create an LLM Agent Node
#'
#' @description
#' A convenience wrapper to instantiate an \code{AgentLLMNode}. Useful for
#' functional-style DAG construction.
#'
#' @param id String.
#' A unique identifier for the node within the DAG.
#' @param role String.
#' The system prompt or identity the LLM should assume (e.g., "Python Developer").
#' @param driver AgentDriver.
#' An R6 driver object (e.g., \code{GeminiCLIDriver}) that handles the LLM API.
#' @param model String.
#' Optional model name override (e.g., "gpt-4"). Defaults to driver default.
#' @param cli_opts List.
#' Optional parameters passed to the underlying CLI or API call.
#' @param ... Additional arguments.
#' Passed directly to the \code{AgentLLMNode$new()} constructor. Useful for
#' setting \code{tools}, \code{prompt_builder}, or \code{output_path}.
#'
#' @return An \code{AgentLLMNode} object.
#'
#' @examples
#' \dontrun{
#' # NOTE: Ensure ANTHROPIC_API_KEY is set in your .Renviron file for this example.
#'
#' driver <- AnthropicAPIDriver$new()
#' node <- add_llm_node(
#'   id = "coder",
#'   role = "You are an expert R programmer.",
#'   driver = driver,
#'   model = "claude-3-sonnet",
#'   output_path = "scripts/generated_code.R"
#' )
#' }
add_llm_node <- function(id, role, driver, model = NULL, cli_opts = list(), ...) {
  AgentLLMNode$new(id = id, role = role, driver = driver, model = model, cli_opts = cli_opts, ...)
}

#' Create an R Logic Node
#'
#' @description
#' A convenience wrapper to instantiate an \code{AgentLogicNode}. Nodes created
#' this way execute pure R code rather than calling an LLM.
#'
#' @param id String.
#' A unique identifier for the node.
#' @param logic_fn Function.
#' An R function that accepts an \code{AgentState} object as its first argument
#' and returns a list with at least \code{status} and \code{output}.
#' @param ... Additional arguments.
#' Passed directly to the \code{AgentLogicNode$new()} constructor.
#'
#' @return An \code{AgentLogicNode} object.
#'
#' @examples
#' \dontrun{
#' # Define a logic function that validates a previous node's output
#' validator <- function(state) {
#'   raw_data <- state$get("data_fetcher")
#'   if (length(raw_data) > 0) {
#'     list(status = "success", output = list(valid = TRUE))
#'   } else {
#'     list(status = "failed", output = list(valid = FALSE))
#'   }
#' }
#'
#' node <- add_logic_node("data_validator", validator)
#' }
add_logic_node <- function(id, logic_fn, ...) {
  AgentLogicNode$new(id = id, logic_fn = logic_fn, ...)
}

#' Add an LLM Agent Node directly to a DAG
#'
#' @description
#' Instantiates an \code{AgentLLMNode} and appends it to the provided \code{AgentDAG}
#' in one step.
#'
#' @param dag AgentDAG.
#' The graph object to which the node will be added.
#' @param id String.
#' Unique identifier for the node.
#' @param role String.
#' System prompt/role for the agent.
#' @param driver AgentDriver.
#' The LLM driver instance.
#' @param model String.
#' Optional model name override.
#' @param cli_opts List.
#' Optional CLI/API parameters.
#' @param ... Additional arguments.
#' Passed to \code{AgentLLMNode$new()}.
#'
#' @return The modified \code{AgentDAG} object (invisibly).
#'
#' @examples
#' \dontrun{
#' # NOTE: Set GOOGLE_API_KEY in your .Renviron for Gemini drivers.
#'
#' dag <- dag_create()
#' dag_add_llm_node(
#'   dag,
#'   id = "summary_node",
#'   role = "Summarise the following text.",
#'   driver = GeminiAPIDriver$new()
#' )
#' }
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
#' @examples
#' \dontrun{
#' dag <- dag_create()
#' dag <- dag_add_logic_node(dag, "node1", function() print("Hello"))
#' }
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
#' @examples
#' \dontrun{
#' node <- standard_node_factory("id", "label")
#' }
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
  "AnthropicCLIDriver", "OpenAIAPIDriver", "GeminiCLIDriver", "GeminiAPIDriver",
  "GeminiImageDriver", "OllamaDriver", "CopilotCLIDriver", "OpenAICodexCLIDriver",
  "AnthropicAPIDriver"
))

#' <!-- APAF Bioinformatics | factory.R | Approved | 2026-03-30 -->

#' Resolve a Default Driver from Shorthand ID
#'
#' @description
#' Provides a mechanism to quickly obtain a pre-configured \code{AgentDriver}
#' using logic-friendly keys like \code{"gemini"}, \code{"claude"}, or \code{"openai"}.
#'
#' @param driver_id String.
#' A shorthand identifier. Supported values include: \code{"gemini"},
#' \code{"gemini_api"}, \code{"anthropic"}, \code{"anthropic_api"},
#' \code{"openai"}, \code{"openai_api"}, and \code{"ollama"}.
#' @param driver_registry DriverRegistry.
#' An optional registry object to look up custom drivers first. If omitted,
#' the global \code{get_driver_registry()} is used.
#'
#' @return An \code{AgentDriver} object.
#'
#' @examples
#' \dontrun{
#' # Retrieve the default Gemini CLI driver
#' drv <- resolve_default_driver("gemini")
#'
#' # Retrieve a registered API driver
#' drv_api <- resolve_default_driver("openai_api")
#' }
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
    "gemini" = GeminiCLIDriver$new(),
    "gemini_api" = GeminiAPIDriver$new(),
    "gemini_image" = GeminiImageDriver$new(),
    "anthropic" = AnthropicCLIDriver$new(),
    "anthropic_api" = AnthropicAPIDriver$new(),
    "openai" = OpenAICodexCLIDriver$new(),
    "openai_api" = OpenAIAPIDriver$new(),
    "ollama" = OllamaDriver$new(),
    stop(sprintf("Unknown driver shorthand: '%s'. Register it first or use a known ID (gemini, gemini_api, gemini_image, anthropic, anthropic_api, openai, openai_api, ollama).", driver_id))
  )
}

#' Internal helper: Build an LLM Node
#' @keywords internal
.build_llm_node <- function(id, label, params, drv_reg) {
  driver_id <- params[["driver"]] %||% "gemini"
  driver_obj <- resolve_default_driver(driver_id, driver_registry = drv_reg)

  role <- params[["role"]]
  if (is.null(role) && !is.null(params[["role_id"]])) {
    role <- get_role(params[["role_id"]])
    if (is.null(role)) {
      role <- get_logic(params[["role_id"]])
    }
  }
  if (is.null(role) || !is.character(role)) {
    stop(sprintf("Node '%s' (type=llm): No role found. Provide 'role=' inline or 'role_id='.", id))
  }

  prompt_builder <- NULL
  if (!is.null(params[["prompt_id"]])) {
    prompt_builder <- get_logic(params[["prompt_id"]])
    if (is.null(prompt_builder)) {
      warning(sprintf("Node '%s': prompt_id '%s' not found.", id, params[["prompt_id"]]))
    }
  }

  AgentLLMNode$new(id = id, role = role, driver = driver_obj, label = label, params = params, prompt_builder = prompt_builder, model = params[["model"]])
}

#' Internal helper: Build a Logic Node
#' @keywords internal
.build_logic_node <- function(id, label, params) {
  logic_id <- params[["logic_id"]]
  if (is.null(logic_id)) stop(sprintf("Node '%s' (type=logic): 'logic_id' parameter is required.", id))
  # Search registry then global environment for backwards compatibility in tests
  logic_fn <- get_logic(logic_id)
  if (is.null(logic_fn)) {
    logic_fn <- tryCatch(get(logic_id, mode = "function"), error = function(e) NULL)
  }
  if (is.null(logic_fn)) stop(sprintf("Node '%s' (type=logic): logic_id '%s' not found in registry.", id, logic_id))
  AgentLogicNode$new(id = id, logic_fn = logic_fn, label = label, params = params)
}

#' Internal helper: Build a Router Node
#' @keywords internal
.build_router_node <- function(id, label, params) {
  logic_id <- params[["logic_id"]]
  if (is.null(logic_id)) stop(sprintf("Node '%s' (type=router): 'logic_id' required.", id))
  router_fn <- get_logic(logic_id)
  if (is.null(router_fn)) {
    router_fn <- tryCatch(get(logic_id, mode = "function"), error = function(e) NULL)
  }
  if (is.null(router_fn)) stop(sprintf("Node '%s' (type=router): logic_id '%s' not found in registry.", id, logic_id))
  AgentRouterNode$new(id = id, router_fn = router_fn, label = label, params = params)
}

#' Internal helper: Build a Map Node
#' @keywords internal
.build_map_node <- function(id, label, params) {
  logic_id <- params[["logic_id"]]
  map_key <- params[["map_key"]]
  if (is.null(logic_id) || is.null(map_key)) stop(sprintf("Node '%s' (type=map): 'logic_id' and 'map_key' required.", id))
  logic_fn <- get_logic(logic_id)
  if (is.null(logic_fn)) {
    logic_fn <- tryCatch(get(logic_id, mode = "function"), error = function(e) NULL)
  }
  if (is.null(logic_fn)) stop(sprintf("Node '%s' (type=map): logic_id '%s' not found in registry.", id, logic_id))
  AgentMapNode$new(id = id, map_key = map_key, logic_fn = logic_fn, label = label, params = params)
}

#' Internal helper: Build an Observer Node
#' @keywords internal
.build_observer_node <- function(id, label, params) {
  logic_id <- params[["logic_id"]]
  if (is.null(logic_id)) stop(sprintf("Node '%s' (type=observer): 'logic_id' required.", id))
  observe_fn <- get_logic(logic_id)
  if (is.null(observe_fn)) {
    observe_fn <- tryCatch(get(logic_id, mode = "function"), error = function(e) NULL)
  }
  if (is.null(observe_fn)) stop(sprintf("Node '%s' (type=observer): logic_id '%s' not found in registry.", id, logic_id))
  AgentObserverNode$new(id = id, observe_fn = observe_fn, label = label, params = params)
}

#' Automatic Node Factory for Mermaid-as-Source
#'
#' @description
#' Generates a closure that can resolve Mermaid node labels into fully
#' instantiated \code{AgentNode} objects based on inline annotations.
#'
#' @details
#' The factory supports the following \code{type=} parameters in Mermaid labels:
#' \itemize{
#'   \item \code{llm}: Creates an \code{AgentLLMNode}. Requires \code{role} or \code{role_id}.
#'   \item \code{logic}: Creates an \code{AgentLogicNode}. Requires \code{logic_id}.
#'   \item \code{router}: Creates an \code{AgentRouterNode}. Requires \code{logic_id}.
#'   \item \code{map}: Creates an \code{AgentMapNode}. Requires \code{logic_id} and \code{map_key}.
#' }
#'
#' @param driver_registry DriverRegistry.
#' An optional registry used to resolve drivers specified in Mermaid
#' annotations (e.g., \code{driver=openai_api}).
#'
#' @return A function that takes \code{(id, label, params)} and returns an \code{AgentNode}.
#'
#' @examples
#' \dontrun{
#' # Define a workflow entirely in Mermaid syntax
#' mermaid_src <- '
#' graph TD
#'   A["Researcher | type=llm | role=Research Assistant | driver=gemini"]
#'   B["Validator | type=logic | logic_id=validate_fn"]
#'   A --> B
#' '
#'
#' # Define the logic referenced in Mermaid
#' register_logic("validate_fn", function(state) {
#'   list(status = "success", output = list(ok = TRUE))
#' })
#'
#' # Spawn the DAG using the automatic factory
#' dag <- AgentDAG$from_mermaid(
#'   mermaid_src,
#'   node_factory = auto_node_factory()
#' )
#' }
#' @export
auto_node_factory <- function(driver_registry = NULL) {
  drv_reg <- driver_registry

  function(id, label, params) {
    node_type <- params[["type"]] %||% "auto"

    switch(node_type,
      "llm" = .build_llm_node(id, label, params, drv_reg),
      "logic" = .build_logic_node(id, label, params),
      "merge" = create_merge_harmonizer(id = id),
      "router" = .build_router_node(id, label, params),
      "map" = .build_map_node(id, label, params),
      "observer" = .build_observer_node(id, label, params),
      "auto" = {
        fn <- get_logic(id)
        if (!is.null(fn)) {
          return(AgentLogicNode$new(id = id, logic_fn = fn, label = label, params = params))
        }
        AgentLogicNode$new(
          id = id,
          logic_fn = function(state) {
            message(sprintf("[auto] Passthrough node '%s'", id))
            list(status = "success", output = NULL)
          },
          label = label,
          params = params
        )
      },
      stop(sprintf("Node '%s': Unknown type '%s'. Supported: llm, logic, merge, auto.", id, node_type))
    )
  }
}

# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        registry.R
# Author:      APAF Agentic Workflow
# Purpose:     Logic Registry for serializable R functions
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

# Internal environment for storing function logic
.hydra_registry <- new.env(parent = emptyenv())

#' Register Logic Function
#' @param name String. Unique identifier for the function.
#' @param fn Function. The R function to store.
#' @return The registry environment (invisibly).
#' @export
register_logic <- function(name, fn) {
  stopifnot(is.character(name) && is.function(fn))
  assign(name, fn, envir = .hydra_registry)
  invisible(.hydra_registry)
}

#' Get Logic Function
#' @param name String. Unique identifier.
#' @return Function or NULL.
#' @export
get_logic <- function(name) {
  if (exists(name, envir = .hydra_registry)) {
    return(get(name, envir = .hydra_registry))
  }
  return(NULL)
}

#' List Registered Components
#' @return Character vector of names.
#' @export
list_logic <- function() {
  ls(envir = .hydra_registry)
}

#' Register an LLM Role (System Prompt)
#' @param name String. Unique identifier for the role.
#' @param prompt_text String. The system prompt text.
#' @return The registry environment (invisibly).
#' @export
register_role <- function(name, prompt_text) {
  stopifnot(is.character(name) && length(name) == 1)
  stopifnot(is.character(prompt_text) && length(prompt_text) == 1)
  assign(paste0("__role__", name), prompt_text, envir = .hydra_registry)
  invisible(.hydra_registry)
}

#' Get an LLM Role (System Prompt)
#' @param name String. Unique identifier.
#' @return String prompt text, or NULL if not found.
#' @export
get_role <- function(name) {
  key <- paste0("__role__", name)
  if (exists(key, envir = .hydra_registry)) {
    return(get(key, envir = .hydra_registry))
  }
  NULL
}

#' List Registered Roles
#' @return Character vector of role names.
#' @export
get_agent_roles <- function() {
  all_keys <- ls(envir = .hydra_registry)
  role_keys <- all_keys[grepl("^__role__", all_keys)]
  gsub("^__role__", "", role_keys)
}

#' Load Multi-Agent Workflow from File
#' @param file_path String. Path to the YAML or JSON workflow definition.
#' @return A list containing elements: 'graph', 'initial_state', 'roles', 'logic', 'raw'.
#' @export
load_workflow <- function(file_path) {
  stopifnot(is.character(file_path) && length(file_path) == 1)
  if (!file.exists(file_path)) {
    stop(sprintf("Workflow file not found: %s", file_path))
  }

  # Detect format
  ext <- tolower(tools::file_ext(file_path))
  raw_data <- if (ext %in% c("yml", "yaml")) {
    yaml::read_yaml(file_path)
  } else if (ext == "json") {
    jsonlite::read_json(file_path, simplifyVector = FALSE)
  } else {
    stop("Unsupported workflow format. Use .yml, .yaml, or .json")
  }

  # 1. Validate Schema
  validate_workflow_schema(raw_data)

  # 2. Register Roles
  if (!is.null(raw_data[["roles"]])) {
    purrr::iwalk(raw_data[["roles"]], function(prompt, name) {
      register_role(name, prompt)
    })
  }

  # 3. Register Logic
  if (!is.null(raw_data[["logic"]])) {
    purrr::iwalk(raw_data[["logic"]], function(v, name) {
      fn <- resolve_logic_pattern(v)
      register_logic(name, fn)
    })
  }

  # 4. Return Workflow Structure
  list(
    graph = raw_data[["graph"]] %||% "",
    initial_state = raw_data[["initial_state"]] %||% list(),
    roles = raw_data[["roles"]] %||% list(),
    logic = raw_data[["logic"]] %||% list(),
    start_node = raw_data[["start_node"]] %||% NULL,
    conditional_edges = raw_data[["conditional_edges"]] %||% list(),
    error_edges = raw_data[["error_edges"]] %||% list(),
    raw = raw_data
  )
}

#' Spawn an AgentDAG from a Workflow Object
#'
#' @description
#' High-level 'Low Code' helper that instantiates, configures, and compiles
#' an AgentDAG based on a workflow list (from `load_workflow`).
#'
#' @param wf List. The workflow object.
#' @param node_factory Function. Defaults to `auto_node_factory()`.
#' @return A compiled `AgentDAG` object.
#' @export
spawn_dag <- function(wf, node_factory = auto_node_factory()) {
  if (!is.list(wf) || is.null(wf$graph)) {
    stop("wf must be a workflow list object with a 'graph' element.")
  }

  # 1. Instantiate from Mermaid
  dag <- mermaid_to_dag(wf$graph, node_factory)

  # 2. Apply Declarative Start Node
  if (!is.null(wf$start_node)) {
    dag$set_start_node(wf$start_node)
  }

  # 2.5 Apply Declarative Conditional Edges
  if (!is.null(wf$conditional_edges) && length(wf$conditional_edges) > 0) {
    purrr::iwalk(wf$conditional_edges, function(cfg, from) {
      test_fn <- resolve_test_pattern(cfg$test)
      dag$add_conditional_edge(
        from = from,
        test = test_fn,
        if_true = cfg$if_true %||% NULL,
        if_false = cfg$if_false %||% NULL
      )
    })
  }

  # 2.6 Apply Declarative Error Edges
  if (!is.null(wf$error_edges) && length(wf$error_edges) > 0) {
    purrr::iwalk(wf$error_edges, function(to, from) {
      dag$add_error_edge(from = from, to = to)
    })
  }

  # 3. Compile
  dag$compile()

  return(dag)
}

# --- Internal Helpers ---

#' Resolve Logic Pattern (3-Tier)
#' @param v String. File path, function name, or code snippet.
#' @return Logic function.
#' @keywords internal
resolve_logic_pattern <- function(v) {
  if (!is.character(v)) {
    stop("Logic entry must be a character string.")
  }

  v_trim <- trimws(v)

  # Tier 1: External R File (source(v)$value)
  if (grepl("\\.[rR]$", v_trim) && file.exists(v_trim)) {
    res <- tryCatch(
      {
        source(v_trim, local = TRUE)$value
      },
      error = function(e) {
        stop(sprintf("Failed to source logic file '%s': %s", v_trim, e$message))
      }
    )
    if (!is.function(res)) {
      stop(sprintf("Logic file '%s' did not return a function. Ensure it ends with an anonymous function definition.", v_trim))
    }
    return(res)
  }

  # Tier 2: Existing Named Function
  # First check our internal registry
  existing_fn <- get_logic(v_trim)
  if (!is.null(existing_fn) && is.function(existing_fn)) {
    return(existing_fn)
  }
  # Then check the search path (globalEnv, packages etc.)
  if (exists(v_trim, mode = "function")) {
    return(get(v_trim, mode = "function"))
  }

  # Tier 3: Anonymous Code Wrapper
  # If it contains brackets, newlines, or assignment - treat as code
  function(state) {
    # Provide 'state' in evaluation environment
    eval(parse(text = v), envir = list(state = state), enclos = parent.frame())
  }
}

#' Simple Workflow Schema Validator
#' @param data List. Parsed YAML/JSON data.
#' @keywords internal
validate_workflow_schema <- function(data) {
  if (!is.list(data)) {
    stop("Workflow data must be a top-level list/object.")
  }

  # Optional but recommended keys
  valid_keys <- c("graph", "roles", "logic", "initial_state", "start_node", "conditional_edges", "metadata")
  found_keys <- names(data)

  unknown <- setdiff(found_keys, valid_keys)
  if (length(unknown) > 0) {
    warning(sprintf("Unknown top-level keys in workflow: %s", paste(unknown, collapse = ", ")))
  }
}

#' Resolve Test Pattern (for Conditional Edges)
#' @param v String or function.
#' @return A function(out) -> Logical.
#' @keywords internal
resolve_test_pattern <- function(v) {
  if (is.function(v)) return(v)
  if (!is.character(v)) stop("Test pattern must be a function or string.")
  
  v_trim <- trimws(v)

  # Check logic registry or search path for named function
  existing_fn <- get_logic(v_trim)
  if (!is.null(existing_fn) && is.function(existing_fn)) return(existing_fn)
  if (exists(v_trim, mode = "function")) return(get(v_trim, mode = "function"))

  # Anonymous Code Wrapper (expects 'out')
  function(out) {
    eval(parse(text = v), envir = list(out = out), enclos = parent.frame())
  }
}

# <!-- APAF Bioinformatics | registry.R | Approved | 2026-03-30 -->

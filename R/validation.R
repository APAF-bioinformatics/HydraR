# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        validation.R
# Author:      APAF Agentic Workflow
# Purpose:     Advanced Workflow & Logic Validation Engine
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Validate HydraR Workflow Integration
#'
#' @description
#' Performs a holistic check on the instantiated DAG and the source workflow.
#' Ensures all roles, logic, and edges are synchronized and syntactically correct.
#'
#' @param dag AgentDAG object.
#' @param wf List. The workflow object from `load_workflow`.
#' @return Logical TRUE if valid, otherwise throws an error.
#' @export
validate_workflow_full <- function(dag, wf) {
  errors <- list()
  warnings <- list()

  # 1. Resource Linkage Verification
  resource_results <- check_resource_linking(dag)
  errors <- c(errors, resource_results$errors)

  # 2. Topology / Edge Synchronization
  topo_results <- check_edge_synchronization(dag)
  errors <- c(errors, topo_results$errors)

  # 3. R Logic Syntactic & Compliance Check
  logic_results <- lint_workflow_logic(wf)
  errors <- c(errors, logic_results$errors)
  warnings <- c(warnings, logic_results$warnings)

  # 4. Report Results
  if (length(warnings) > 0) {
    purrr::walk(warnings, ~ message(sprintf("[HydraR Warning] %s", .x)))
  }

  if (length(errors) > 0) {
    err_msg <- paste(
      "Orchestration Validation Failed!",
      paste(purrr::imap_chr(errors, ~ sprintf("%d. %s", .y, .x)), collapse = "\n"),
      "\nAction: Please synchronize the graph, roles, and logic sections in your workflow file.",
      sep = "\n\n"
    )
    stop(err_msg, call. = FALSE)
  }

  return(TRUE)
}

#' Check Resource Linking (Roles & Logic)
#' @param dag AgentDAG.
#' @return List(errors, warnings).
#' @keywords internal
check_resource_linking <- function(dag) {
  errors <- list()

  purrr::walk(dag$nodes, function(node) {
    # Role Check (LLM Nodes)
    if (inherits(node, "AgentLLMNode")) {
      role_id <- node$params$role_id
      if (!is.null(role_id)) {
        if (is.null(get_role(role_id))) {
          errors <<- c(errors, sprintf("Node '%s': Role ID '%s' not found in registry. Check your 'roles:' section.", node$id, role_id))
        }
      }
    }

    # Logic Check (Logic Nodes)
    # Note: Logic nodes might use logic_id or role_id (deprecated shorthand)
    if (inherits(node, "AgentLogicNode")) {
      logic_id <- node$params$logic_id %||% node$params$role_id
      if (!is.null(logic_id)) {
        # Skip special 'merge' nodes which are handled by factory
        if (node$label == "Merge Harmonizer") {
          return()
        }

        if (is.null(get_logic(logic_id))) {
          errors <<- c(errors, sprintf("Node '%s': Logic ID '%s' not found in registry. Check your 'logic:' section.", node$id, logic_id))
        }
      }
    }
  })

  list(errors = errors)
}

#' Check Edge Synchronization
#' @param dag AgentDAG.
#' @return List(errors).
#' @keywords internal
check_edge_synchronization <- function(dag) {
  errors <- list()

  # Get all static edges defined in Mermaid (stored in dag$edges)
  # Format: list(from, to, label)
  static_edges <- dag$edges

  # Helper to check if a specific edge exists in static topology
  has_static_edge <- function(from, to) {
    purrr::some(static_edges, ~ .x$from == from && .x$to == to)
  }

  purrr::iwalk(dag$conditional_edges, function(cfg, node_id) {
    # Get all outgoing edges defined in Mermaid for this node
    mermaid_targets <- purrr::keep(static_edges, ~ .x$from == node_id) |>
      purrr::map_chr(~ .x$to)

    # 1. Verify that YAML targets actually have arrows in Mermaid
    # Check if_true
    if (!is.null(cfg$if_true)) {
      if (!has_static_edge(node_id, cfg$if_true)) {
        errors <<- c(errors, sprintf("Node '%s': YAML defines 'if_true: %s', but no matching arrow (-->) exists in the Mermaid graph.", node_id, cfg$if_true))
      }
    }

    # Check if_false
    if (!is.null(cfg$if_false)) {
      if (!has_static_edge(node_id, cfg$if_false)) {
        errors <<- c(errors, sprintf("Node '%s': YAML defines 'if_false: %s', but no matching arrow (-->) exists in the Mermaid graph.", node_id, cfg$if_false))
      }
    }

    # 2. Verify that Mermaid arrows for this node are all handled by YAML logic
    # (Prevent 'ghost' edges that are visually present but logically dead)
    logical_targets <- purrr::compact(list(cfg$if_true, cfg$if_false))
    unmanaged_edges <- setdiff(mermaid_targets, logical_targets)

    # Allow 'error' edges if defined separately
    if (node_id %in% names(dag$error_edges)) {
      unmanaged_edges <- setdiff(unmanaged_edges, dag$error_edges[[node_id]])
    }

    if (length(unmanaged_edges) > 0) {
      errors <<- c(errors, sprintf("Node '%s': Mermaid graph has extra edges to [%s] that are not handled by 'conditional_edges' in YAML.", node_id, paste(unmanaged_edges, collapse = ", ")))
    }
  })

  list(errors = errors)
}

#' Lint Workflow Logic
#' @param wf List. The workflow object.
#' @return List(errors, warnings).
#' @keywords internal
lint_workflow_logic <- function(wf) {
  errors <- list()
  warnings <- list()

  if (is.null(wf$logic)) {
    return(list(errors = list(), warnings = list()))
  }

  purrr::iwalk(wf$logic, function(code, name) {
    if (!is.character(code)) {
      return()
    }

    v_trim <- trimws(code)
    # If the logic entry is a file path, read the file content for linting
    if (grepl("\\.[rR]$", v_trim, ignore.case = TRUE) && file.exists(v_trim)) {
      code_content <- tryCatch(
        paste(readLines(v_trim, warn = FALSE), collapse = "\n"),
        error = function(e) code
      )
      code <- code_content
    }

    # 1. Syntactic Parse Check (Hard Stop)
    parse_res <- tryCatch(
      {
        parse(text = code)
        NULL
      },
      error = function(e) {
        errors <<- c(errors, sprintf("Logic '%s': Syntactic error - %s", name, e$message))
        e
      }
    )
    if (!is.null(parse_res)) {
      return()
    }

    # 2. APAF Rule G-25: No for-loops
    # Simple regex check for 'for(' or 'for '
    if (grepl("\\bfor\\s*\\(", code)) {
      warnings <<- c(warnings, sprintf("Logic '%s': Violation of APAF Global Rule G-25 ('for' loop detected). Use purrr::map/walk instead.", name))
    }

    # 3. Signature Check (Heuristic)
    # If the code looks like a function(state), check it
    # If it's a code block that HydraR wraps, it implicitly uses 'state'
    # We can check if 'state' is mentioned in the code
    # SKIP if it's a simple identifier (alphanumeric only, no spaces/parens)
    is_simple_id <- grepl("^[a-zA-Z0-9_]+$", v_trim)
    if (!is_simple_id && !grepl("\\bstate\\b", code) && !grepl("^\\{", trimws(code))) {
      warnings <<- c(warnings, sprintf("Logic '%s': 'state' object is not referenced. Ensure your logic interacts with the AgentState.", name))
    }

    # 4. lintr integration (if available)
    if (requireNamespace("lintr", quietly = TRUE)) {
      l_res <- lintr::lint(text = code)
      if (length(l_res) > 0) {
        # We limit to first 3 lints per block to avoid noise
        purrr::walk(utils::head(l_res, 3), function(l) {
          warnings <<- c(warnings, sprintf("Logic '%s' [Lint]: %s (line %d)", name, l$message, l$line_number))
        })
      }
    }
  })

  list(errors = errors, warnings = warnings)
}

#' Validate Workflow File Syntax and Consistency
#'
#' @description
#' A high-level helper that performs a comprehensive check on a YAML/JSON workflow file.
#' This includes schema validation, topological consistency checks (Mermaid vs YAML),
#' and R logic syntax linting.
#'
#' @param file_path String. Path to the workflow definition file.
#' @return Logical TRUE if valid (invisibly). Throws a detailed error on failure.
#' @export
validate_workflow_file <- function(file_path) {
  wf <- load_workflow(file_path)
  # spawn_dag internally calls validate_workflow_full
  dag <- spawn_dag(wf)
  invisible(TRUE)
}

#' Render Workflow Diagram from File
#'
#' @description
#' Loads a workflow from a file and renders its architecture as a Mermaid diagram.
#' Supports high-fidelity exports to various image formats.
#'
#' @param file_path String. Path to the YAML workflow file.
#' @param output_file String. Optional path to save the diagram (e.g., "plot.png").
#' Supported extensions: .png, .pdf, .svg.
#' @param status Logical. If TRUE, styling is applied (requires a valid trace log in the workflow state).
#' @param ... Additional arguments passed to `dag$run()`.
#' @return A `DiagrammeR` htmlwidget if `output_file` is NULL, otherwise saves the file.
#' @export
render_workflow_file <- function(file_path, output_file = NULL, status = FALSE, ...) {
  wf <- load_workflow(file_path)
  dag <- spawn_dag(wf)

  if (is.null(output_file)) {
    m_str <- dag$plot(type = "mermaid", status = status, ...)
    # DiagrammeR::mermaid doesn't need the fences
    clean_m <- gsub("^```mermaid\\n|\\n```$", "", m_str)
    return(DiagrammeR::mermaid(clean_m))
  }

  # Export logic (requires DiagrammeRsvg and rsvg)
  # NOTE: We use grViz (Graphviz) for exports because DiagrammeRsvg::export_svg
  # only supports Graphviz-based htmlwidgets, not Mermaid.
  if (!requireNamespace("DiagrammeRsvg", quietly = TRUE)) {
    stop("Package 'DiagrammeRsvg' is required for exporting diagrams.")
  }
  if (!requireNamespace("rsvg", quietly = TRUE)) {
    stop("Package 'rsvg' is required for exporting diagrams.")
  }

  dot_str <- dag$plot(type = "grViz", status = status, ...)
  widget <- DiagrammeR::grViz(dot_str)
  svg_code <- DiagrammeRsvg::export_svg(widget)

  ext <- tolower(tools::file_ext(output_file))
  switch(ext,
    "svg" = writeLines(svg_code, output_file),
    "pdf" = rsvg::rsvg_pdf(charToRaw(svg_code), output_file),
    "png" = rsvg::rsvg_png(charToRaw(svg_code), output_file),
    "jpg" = stop("JPEG export is not supported by 'rsvg'. Please use .png, .pdf, or .svg.", call. = FALSE),
    "jpeg" = stop("JPEG export is not supported by 'rsvg'. Please use .png, .pdf, or .svg.", call. = FALSE),
    stop(sprintf("Unsupported output format: %s", ext))
  )

  invisible(NULL)
}

# <!-- APAF Bioinformatics | validation.R | Approved | 2026-04-03 -->

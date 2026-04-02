# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        mermaid_parser.R
# Author:      APAF Agentic Workflow
# Purpose:     Regex-based Mermaid to DAG Parser
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Clean Mermaid Lines
#'
#' @param mermaid_str Raw Mermaid syntax string.
#' @return A character vector of cleaned, non-empty lines.
#' @noRd
clean_mermaid_lines <- function(mermaid_str) {
  if (is.null(mermaid_str) || mermaid_str == "") {
    return(character(0))
  }

  lines <- strsplit(mermaid_str, "\\n")[[1]]
  lines <- trimws(lines)
  # Remove lines that are empty, code block guards, comments, or start with graph/flowchart
  lines <- lines[nzchar(lines) & !grepl("^```", lines) & !grepl("^%%", lines) & !grepl("^(graph|flowchart)", lines, ignore.case = TRUE)]

  return(lines)
}

#' Extract Edge Labels and Node Parts from a Line
#'
#' @param line A single line of Mermaid syntax.
#' @return A list with `edge_labels` (character vector) and `parts` (character vector of node strings).
#' @noRd
extract_edge_and_node_strings <- function(line) {
  # 1. Identify arrows using control character guards to prevent overlap
  # We use [^>-] to avoid accidental ASCII range interpretation.
  line_work <- line
  line_work <- gsub("--\\s*([^>-]+?)\\s*-->", "\001\\1\002", line_work)
  line_work <- gsub("-->\\s*\\|(.*?)\\|", "\001\\1\002", line_work)
  line_work <- gsub("-->", "\001\002", line_work)

  # 2. Extract edge labels and nodes using regmatches (canonical split)
  m <- gregexpr("\001[^\002]*\002", line_work, perl = TRUE)
  if (m[[1]][1] == -1) {
    parts <- line
    edge_labels <- character(0)
  } else {
    # Extract labels
    all_match_strs <- regmatches(line_work, m)[[1]]
    edge_labels <- purrr::map_chr(all_match_strs, function(match_str) {
      lbl <- gsub("^\001|\002$", "", match_str)
      # Also strip leading/trailing quotes from the label
      gsub("^\"|\"$", "", trimws(lbl))
    })

    # Extract nodes (parts between arrows)
    parts <- regmatches(line_work, m, invert = TRUE)[[1]]
    parts <- trimws(parts)
    parts <- parts[nzchar(parts)]
  }

  list(edge_labels = edge_labels, parts = parts)
}

#' Extract Parameters from Label Text
#'
#' @param label_text The label string potentially containing parameters separated by `|`.
#' @return A list with `label` (clean label) and `params` (list of parsed parameters).
#' @noRd
extract_params <- function(label_text) {
  params <- list()
  label <- label_text

  if (grepl("\\|", label_text)) {
    bits <- strsplit(label_text, "\\|")[[1]]
    label <- trimws(bits[1])
    param_strings <- trimws(bits[-1])

    purrr::walk(param_strings, function(ps) {
      # Clean up any leftover brackets in param values
      ps <- gsub("[\\]\\)\\}\\>[:space:]]+$", "", ps)
      if (grepl("=", ps)) {
        kv <- strsplit(ps, "=")[[1]]
        key <- trimws(kv[1])
        val <- trimws(paste(kv[-1], collapse = "="))
        val_lower <- tolower(val)
        
        # Handle list-based parameters
        if (key %in% c("agents_files", "skills_files")) {
          coerced_val <- trimws(strsplit(val, ",")[[1]])
        } else {
          coerced_val <- if (val_lower == "null") {
            NULL
          } else if (val_lower %in% c("na", "nan")) {
            NA
          } else if (grepl("^-?\\d+(\\.\\d+)?$", val)) {
            as.numeric(val)
          } else if (val_lower == "true") {
            TRUE
          } else if (val_lower == "false") {
            FALSE
          } else {
            val
          }
        }
        params[[key]] <<- coerced_val
      }
    })
  }

  list(label = label, params = params)
}

#' Parse Node String
#'
#' @param p A string representing a node (e.g., `A["Node A"]`).
#' @return A list with `id`, `label`, and `params`.
#' @noRd
parse_node_string <- function(p) {
  if (!nzchar(p)) {
    return(NULL)
  }

  # Heuristic for ID and Label
  # Cases: ID[Label], ID(Label), ID{Label}, ID>Label], or just ID
  bracket_info <- regexpr("[\\[\\(\\{\\>]", p)
  if (bracket_info != -1) {
    id <- trimws(substr(p, 1, bracket_info - 1))
    open_b <- substr(p, bracket_info, bracket_info)
    close_b <- if (open_b == "[") "]" else if (open_b == "(") ")" else if (open_b == "{") "}" else if (open_b == ">") "]" else ""
    remainder <- substr(p, bracket_info + 1, nchar(p))

    # Strip trailing brackets and quotes from remainder
    clean_remainder <- gsub(paste0("\\", close_b, "[[:space:]]*$"), "", remainder)
    label_text <- trimws(gsub("^\"|\"$", "", clean_remainder))
  } else {
    id <- p
    label_text <- id
  }

  param_info <- extract_params(label_text)

  list(id = id, label = param_info$label, params = param_info$params)
}

#' Build Nodes DataFrame
#'
#' @param all_nodes_raw A list of raw parsed nodes.
#' @return A data.frame containing deduplicated nodes with a list-column for parameters.
#' @noRd
build_nodes_df <- function(all_nodes_raw) {
  node_map <- list()
  purrr::walk(all_nodes_raw, function(node) {
    id <- node$id
    if (is.null(node_map[[id]])) {
      node_map[[id]] <<- list(label = node$label, params = node$params)
    } else {
      # Merge params and update label if more descriptive
      current <- node_map[[id]]
      new_label <- if (current$label == id && node$label != id) node$label else current$label
      new_params <- utils::modifyList(current$params, node$params)
      node_map[[id]] <<- list(label = new_label, params = new_params)
    }
  })

  if (length(node_map) > 0) {
    df <- data.frame(
      id = names(node_map),
      label = purrr::map_chr(node_map, "label"),
      stringsAsFactors = FALSE
    )
    df$params <- lapply(node_map, function(x) x$params)
    df
  } else {
    df <- data.frame(id = character(), label = character(), stringsAsFactors = FALSE)
    df$params <- list()
    df
  }
}

#' Build Edges DataFrame
#'
#' @param all_edges_list A list of raw parsed edges.
#' @return A data.frame containing edges.
#' @noRd
build_edges_df <- function(all_edges_list) {
  if (length(all_edges_list) > 0) {
    do.call(rbind, lapply(all_edges_list, as.data.frame, stringsAsFactors = FALSE))
  } else {
    data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
  }
}

#' Parse Mermaid Flowchart Syntax
#'
#' @description
#' Extracts nodes and edges from 'graph TD' or 'flowchart TD' strings.
#' Supports basic node labels and directed edges.
#'
#' @param mermaid_str String. Mermaid syntax.
#' @return A list containing `nodes` (data.frame) and `edges` (data.frame).
#' @examples
#' mermaid <- "graph TD\n  A --> B"
#' parse_mermaid(mermaid)
#' @importFrom purrr walk map map_chr compact flatten list_flatten
#' @export
parse_mermaid <- function(mermaid_str) {
  lines <- clean_mermaid_lines(mermaid_str)

  if (length(lines) == 0) {
    return(list(nodes = data.frame(), edges = data.frame()))
  }

  raw_results <- purrr::map(lines, function(line) {
    extraction <- extract_edge_and_node_strings(line)

    line_nodes_raw <- purrr::map(extraction$parts, parse_node_string)
    line_nodes <- purrr::compact(line_nodes_raw)

    if (length(line_nodes) == 0) {
      return(list(nodes = list(), edges = list()))
    }

    line_node_ids <- purrr::map_chr(line_nodes, ~ .x$id)
    line_edges <- list()
    if (length(line_node_ids) >= 2) {
      n_edge_slots <- min(length(line_node_ids) - 1, length(extraction$edge_labels))
      line_edges <- purrr::map(seq_len(n_edge_slots), function(i) {
        list(from = line_node_ids[i], to = line_node_ids[i + 1], label = extraction$edge_labels[i])
      })
    }

    list(nodes = line_nodes, edges = line_edges)
  })

  all_nodes_raw <- purrr::list_flatten(purrr::map(raw_results, ~ .x$nodes))
  all_edges_list <- purrr::list_flatten(purrr::map(raw_results, ~ .x$edges))

  nodes_df <- build_nodes_df(all_nodes_raw)
  edges_df <- build_edges_df(all_edges_list)

  return(list(nodes = nodes_df, edges = edges_df))
}

# <!-- APAF Bioinformatics | mermaid_parser.R | Approved | 2026-03-31 -->

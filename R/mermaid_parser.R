# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        mermaid_parser.R
# Author:      APAF Agentic Workflow
# Purpose:     Regex-based Mermaid to DAG Parser
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

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
#' @importFrom purrr walk map map_chr compact flatten
#' @export
parse_mermaid <- function(mermaid_str) {
  if (is.null(mermaid_str) || mermaid_str == "") {
    return(list(nodes = data.frame(), edges = data.frame()))
  }

  # Clean up input - remove line numbers if present, trim, and skip header/guards
  lines <- strsplit(mermaid_str, "\\n")[[1]]
  lines <- trimws(lines)
  # Remove lines that are empty, code block guards, or start with graph/flowchart
  lines <- lines[nzchar(lines) & !grepl("^```", lines) & !grepl("^(graph|flowchart)", lines, ignore.case = TRUE)]

  node_pattern <- "^([A-Za-z0-9_]+)(?:\\[+\"?(.*?)\"?\\]+|\\(+\"?(.*?)\"?\\)+|\\{+\"?(.*?)\"?\\}+|\\>+\"?(.*?)\"?\\]+|)?"

  # First pass: Extract raw node definitions and edge definitions per line
  raw_results <- purrr::map(lines, function(line) {
    # Normalize arrows to a standard format: NODE || LABEL || NODE for easier parsing
    line_norm <- gsub("--\\s*(.*?)\\s*-->", " @@@\\1@@@ ", line)
    line_norm <- gsub("-->\\s*\\|(.*?)\\|", " @@@\\1@@@ ", line_norm)
    line_norm <- gsub("-->", " @@@@@@ ", line_norm)

    # Split line into potential node parts
    parts <- strsplit(line_norm, "\\s+@@@(.*?)@@@\\s+")[[1]]

    # Extract edge labels
    edge_labels_matches <- gregexpr("@@@(.*?)@@@", line_norm)
    edge_labels <- regmatches(line_norm, edge_labels_matches)[[1]]
    edge_labels <- gsub("@@@", "", edge_labels)

    # Process parts as node definitions
    line_nodes_raw <- purrr::map(parts, function(p) {
      p <- trimws(p)
      if (!nzchar(p)) {
        return(NULL)
      }
      m <- regexec(node_pattern, p)
      if (m[[1]][1] == -1) {
        return(NULL)
      }

      matches <- regmatches(p, m)[[1]]
      id <- matches[2]
      # Find the first non-empty label match from various brackets
      label_matches <- matches[3:length(matches)]
      label <- label_matches[nzchar(label_matches)][1]
      if (is.na(label) || is.null(label)) label <- id

      list(id = id, label = label)
    })
    line_nodes <- purrr::compact(line_nodes_raw)

    if (length(line_nodes) == 0) {
      return(list(nodes = list(), edges = list()))
    }

    line_node_ids <- purrr::map_chr(line_nodes, function(node) node$id)

    # Build edges for this line
    line_edges <- list()
    if (length(line_node_ids) >= 2) {
      n_edges <- min(length(line_node_ids) - 1, length(edge_labels))
      line_edges <- purrr::map(seq_len(n_edges), function(i) {
        list(from = line_node_ids[i], to = line_node_ids[i + 1], label = edge_labels[i])
      })
    }

    list(nodes = line_nodes, edges = line_edges)
  })

  # Flatten results
  all_nodes_list <- purrr::flatten(purrr::map(raw_results, ~ .x$nodes))
  all_edges_list <- purrr::flatten(purrr::map(raw_results, ~ .x$edges))

  # Process Nodes: Deduplicate and prioritize explicit labels
  node_map <- list()
  purrr::walk(all_nodes_list, function(node) {
    id <- node$id
    if (is.null(node_map[[id]]) || (node_map[[id]] == id && node$label != id)) {
      node_map[[id]] <<- node$label
    }
  })

  nodes_df <- if (length(node_map) > 0) {
    data.frame(
      id = names(node_map),
      label = as.character(node_map),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(id = character(), label = character(), stringsAsFactors = FALSE)
  }

  # Process Edges: Convert to dataframe
  edges_df <- if (length(all_edges_list) > 0) {
    do.call(rbind, lapply(all_edges_list, as.data.frame, stringsAsFactors = FALSE))
  } else {
    data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
  }

  # Final cleanup
  if (nrow(nodes_df) > 0) rownames(nodes_df) <- NULL
  if (nrow(edges_df) > 0) rownames(edges_df) <- NULL

  return(list(nodes = nodes_df, edges = edges_df))
}

#' <!-- APAF Bioinformatics | mermaid_parser.R | Approved | 2026-03-29 -->

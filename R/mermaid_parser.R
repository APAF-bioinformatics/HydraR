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
  lines <- clean_mermaid_lines(mermaid_str)
  if (length(lines) == 0) {
    return(list(nodes = build_nodes_df(NULL), edges = build_edges_df(NULL)))
  }

  raw_results <- purrr::map(lines, function(line) {
    extracted <- extract_edge_and_node_strings(line)
    node_strings <- extracted$node_strings
    edge_labels <- extracted$edge_labels

    line_nodes_raw <- purrr::map(node_strings, function(ns) {
      node_info <- parse_node_string(ns)
      if (is.null(node_info)) return(NULL)
      
      params_info <- extract_params(node_info$label_text)
      list(id = node_info$id, label = params_info$label, params = params_info$params)
    })
    line_nodes <- purrr::compact(line_nodes_raw)
    
    if (length(line_nodes) == 0) return(list(nodes = list(), edges = list()))

    line_node_ids <- purrr::map_chr(line_nodes, ~ .x$id)
    line_edges <- list()
    if (length(line_node_ids) >= 2) {
      n_edge_slots <- min(length(line_node_ids) - 1, length(edge_labels))
      line_edges <- purrr::map(seq_len(n_edge_slots), function(i) {
        list(from = line_node_ids[i], to = line_node_ids[i + 1], label = edge_labels[i])
      })
    }
    list(nodes = line_nodes, edges = line_edges)
  })

  # Flatten results using list_flatten to handle lists of edges correctly
  all_nodes_raw <- purrr::list_flatten(purrr::map(raw_results, ~ .x$nodes))
  all_edges_list <- purrr::list_flatten(purrr::map(raw_results, ~ .x$edges))

  nodes_df <- build_nodes_df(all_nodes_raw)
  edges_df <- build_edges_df(all_edges_list)

  return(list(nodes = nodes_df, edges = edges_df))
}

# --- Internal Helpers ---

clean_mermaid_lines <- function(mermaid_str) {
  if (is.null(mermaid_str) || mermaid_str == "") return(character(0))
  lines <- strsplit(mermaid_str, "\\n")[[1]]
  lines <- trimws(lines)
  # Remove lines that are empty, code block guards, or start with graph/flowchart
  lines[nzchar(lines) & !grepl("^```", lines) & !grepl("^(graph|flowchart)", lines, ignore.case = TRUE)]
}

extract_edge_and_node_strings <- function(line) {
  # Normalize line: replace arrows with highly distinct unique markers
  # 1. Identify arrows using control character guards to prevent overlap
  line_work <- line
  line_work <- gsub("--\\s*([^>-]+?)\\s*-->", "\001\\1\002", line_work)
  line_work <- gsub("-->\\s*\\|(.*?)\\|", "\001\\1\002", line_work)
  line_work <- gsub("-->", "\001\002", line_work)

  # 2. Extract edge labels and nodes
  m <- gregexpr("\001[^\002]*\002", line_work, perl = TRUE)
  if (m[[1]][1] == -1) {
    return(list(node_strings = line, edge_labels = character(0)))
  }
  
  # Extract labels
  all_match_strs <- regmatches(line_work, m)[[1]]
  edge_labels <- purrr::map_chr(all_match_strs, function(match_str) {
    clean_label <- gsub("^\001|\002$", "", match_str)
    # Strip quotes and trim whitespace
    trimws(gsub("^\"|\"$", "", clean_label))
  })

  # Extract nodes (parts between arrows)
  node_strings <- regmatches(line_work, m, invert = TRUE)[[1]]
  node_strings <- trimws(node_strings)
  node_strings <- node_strings[nzchar(node_strings)]
  
  list(node_strings = node_strings, edge_labels = edge_labels)
}

parse_node_string <- function(node_str) {
  if (!nzchar(node_str)) return(NULL)
  
  # Cases: ID[Label], ID(Label), ID{Label}, ID>Label], or just ID
  bracket_info <- regexpr("[\\[\\(\\{\\>]", node_str)
  if (bracket_info != -1) {
    id <- trimws(substr(node_str, 1, bracket_info - 1))
    open_b <- substr(node_str, bracket_info, bracket_info)
    close_b <- if (open_b == "[") "]" else if (open_b == "(") ")" else if (open_b == "{") "}" else if (open_b == ">") "]" else ""
    remainder <- substr(node_str, bracket_info + 1, nchar(node_str))
    
    # Strip trailing brackets and quotes from remainder
    clean_remainder <- gsub(paste0("\\", close_b, "[[:space:]]*$"), "", remainder)
    label_text <- trimws(gsub("^\"|\"$", "", clean_remainder))
  } else {
    id <- node_str
    label_text <- id
  }
  
  list(id = id, label_text = label_text)
}

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
        coerced_val <- if (val_lower == "null") NULL 
                       else if (val_lower %in% c("na", "nan")) NA 
                       else if (grepl("^-?\\d+(\\.\\d+)?$", val)) as.numeric(val)
                       else if (val_lower == "true") TRUE
                       else if (val_lower == "false") FALSE
                       else val
        params[[key]] <<- coerced_val
      }
    })
  }
  list(label = label, params = params)
}

build_nodes_df <- function(all_nodes_raw) {
  # Deduplicate and prioritize explicit labels/params
  node_map <- list()
  purrr::walk(all_nodes_raw, function(node) {
    id <- node$id
    if (is.null(node_map[[id]]) || (node_map[[id]]$label == id && node$label != id) || length(node$params) > 0) {
      node_map[[id]] <<- list(label = node$label, params = node$params)
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

build_edges_df <- function(all_edges_list) {
  if (length(all_edges_list) > 0) {
    do.call(rbind, lapply(all_edges_list, as.data.frame, stringsAsFactors = FALSE))
  } else {
    data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
  }
}

#' <!-- APAF Bioinformatics | mermaid_parser.R | Approved | 2026-03-29 -->

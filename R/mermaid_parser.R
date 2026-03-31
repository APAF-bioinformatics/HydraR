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

  # Node pattern matching various bracket styles: [], (), {}, >]
  # We split this into two cases: quoted and unquoted labels
  node_pattern <- "^([A-Za-z0-9_]+)(?:\n?(\\[+|\\(+|\\{+|\\>+))?(?:\"(.*?)\"|(.*?))?(?:\\]+|\\)+|\\}+)?$"

  # 1. Normalize line: replace arrows with highly distinct unique markers
  raw_results <- purrr::map(lines, function(line) {
    # 1. Identify arrows using control character guards to prevent overlap
    # We use [^>-] to avoid accidental ASCII range interpretation.
    line_work <- line
    line_work <- gsub("--\\s*([^>-]+?)\\s*-->", "\001\\1\002", line_work)
    line_work <- gsub("-->\\s*\\|(.*?)\\|", "\001\\1\002", line_work)
    line_work <- gsub("-->", "\001\002", line_work)
    # cat(sprintf("DEBUG LINE_WORK: '%s'\n", encodeString(line_work)))

    # 2. Extract edge labels and nodes using regmatches (canonical split)
    m <- gregexpr("\001[^\002]*\002", line_work, perl = TRUE)
    if (m[[1]][1] == -1) {
      parts <- line
      edge_labels <- character(0)
    } else {
      # Extract labels
      all_match_strs <- regmatches(line_work, m)[[1]]
      edge_labels <- purrr::map_chr(all_match_strs, function(match_str) {
        gsub("^\001|\002$", "", match_str)
      })

      # Extract nodes (parts between arrows)
      parts <- regmatches(line_work, m, invert = TRUE)[[1]]
      parts <- trimws(parts)
      parts <- parts[nzchar(parts)]
    }

    # Process parts as node definitions
    line_nodes_raw <- purrr::map(parts, function(p) {
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

      # Parameter Extraction (Pipe Delimiter: "Label | key=value")
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
            params[[key]] <<- coerced_val
          }
        })
      }

      list(id = id, label = label, params = params)
    })
    line_nodes <- purrr::compact(line_nodes_raw)
    if (length(line_nodes) == 0) {
      return(list(nodes = list(), edges = list()))
    }

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

  # Process Nodes: Deduplicate and prioritize explicit labels/params
  node_map <- list()
  purrr::walk(all_nodes_raw, function(node) {
    id <- node$id
    if (is.null(node_map[[id]]) || (node_map[[id]]$label == id && node$label != id) || length(node$params) > 0) {
      node_map[[id]] <<- list(label = node$label, params = node$params)
    }
  })

  nodes_df <- if (length(node_map) > 0) {
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

  # Process Edges: Convert to dataframe
  edges_df <- if (length(all_edges_list) > 0) {
    do.call(rbind, lapply(all_edges_list, as.data.frame, stringsAsFactors = FALSE))
  } else {
    data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
  }

  return(list(nodes = nodes_df, edges = edges_df))
}

#' <!-- APAF Bioinformatics | mermaid_parser.R | Approved | 2026-03-29 -->

#' ──────────────────────────────────────────────────────────────
#' APAF Bioinformatics | Macquarie University
#' File:        mermaid_parser.R
#' Author:      APAF Agentic Workflow
#' Purpose:     Regex-based Mermaid to DAG Parser
#' Licence:     LGPL-3.0 (see LICENCE)
#' ──────────────────────────────────────────────────────────────

#' Parse Mermaid Flowchart Syntax
#' 
#' @description
#' Extracts nodes and edges from 'graph TD' or 'flowchart TD' strings.
#' Supports basic node labels and directed edges.
#'
#' @param mermaid_str String. Mermaid syntax.
#' @return List with 'nodes' (data.frame) and 'edges' (data.frame).
#' @export
parse_mermaid <- function(mermaid_str) {
    if (is.null(mermaid_str) || mermaid_str == "") return(NULL)
    
    # Clean up input
    lines <- strsplit(mermaid_str, "\\n")[[1]]
    lines <- trimws(lines)
    lines <- lines[lines != "" & !grepl("^```", lines) & !grepl("^(graph|flowchart)", lines)]
    
    nodes <- list()
    edges <- list()
    
    node_pattern <- "^([A-Za-z0-9_]+)(?:\\[+\"?(.*?)\"?\\]+|\\(+\"?(.*?)\"?\\)+|\\{+\"?(.*?)\"?\\}+|\\>+\"?(.*?)\"?\\]+|)?"

    for (line in lines) {
        # 1. Normalize arrows to a standard format: NODE || LABEL || NODE
        # Handle -- label -->
        line_norm <- gsub("--\\s*(.*?)\\s*-->", " @@@\\1@@@ ", line)
        # Handle -->|label|
        line_norm <- gsub("-->\\s*\\|(.*?)\\|", " @@@\\1@@@ ", line_norm)
        # Handle -->
        line_norm <- gsub("-->", " @@@@@@ ", line_norm)
        
        parts <- strsplit(line_norm, "\\s+@@@(.*?)@@@\\s+")[[1]]
        # Extract the labels
        edge_labels_matches <- gregexpr("@@@(.*?)@@@", line_norm)
        edge_labels <- regmatches(line_norm, edge_labels_matches)[[1]]
        edge_labels <- gsub("@@@", "", edge_labels)
        
        # Now 'parts' are node definitions
        line_node_ids <- character()
        for (p in parts) {
            p <- trimws(p)
            if (p == "") next
            m <- regexec(node_pattern, p)
            if (m[[1]][1] != -1) {
                matches <- regmatches(p, m)[[1]]
                id <- matches[2]
                label <- Filter(function(x) x != "", matches[3:length(matches)])[1]
                if (is.na(label)) label <- id
                
                if (!(id %in% names(nodes)) || label != id) {
                    nodes[[id]] <- list(id = id, label = label)
                }
                line_node_ids <- c(line_node_ids, id)
            }
        }
        
        # Create edges
        if (length(line_node_ids) >= 2 && length(edge_labels) >= length(line_node_ids) - 1) {
            for (i in 1:(length(line_node_ids) - 1)) {
                edges[[length(edges) + 1]] <- list(
                    from = line_node_ids[i],
                    to = line_node_ids[i+1],
                    label = edge_labels[i]
                )
            }
        } else if (length(parts) == 1) {
             # Single node definition
             p <- trimws(parts[1])
             m <- regexec(node_pattern, p)
             if (m[[1]][1] != -1) {
                 matches <- regmatches(p, m)[[1]]
                 id <- matches[2]
                 label <- Filter(function(x) x != "", matches[3:length(matches)])[1]
                 if (is.na(label)) label <- id
                 if (!(id %in% names(nodes)) || label != id) {
                    nodes[[id]] <- list(id = id, label = label)
                 }
             }
        }
    }
    
    # Convert lists to DataFrames
    nodes_df <- if (length(nodes) > 0) {
        do.call(rbind, lapply(nodes, as.data.frame, stringsAsFactors = FALSE))
    } else {
        data.frame(id = character(), label = character(), stringsAsFactors = FALSE)
    }
    
    edges_df <- if (length(edges) > 0) {
        do.call(rbind, lapply(edges, as.data.frame, stringsAsFactors = FALSE))
    } else {
        data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)
    }
    
    # Ensure rownames are not added
    rownames(nodes_df) <- NULL
    rownames(edges_df) <- NULL
    
    return(list(nodes = nodes_df, edges = edges_df))
}

# <!-- APAF Bioinformatics | mermaid_parser.R | Approved | 2026-03-29 -->

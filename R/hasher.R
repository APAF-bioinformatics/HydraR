# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        hasher.R
# Author:      APAF Agentic Workflow
# Purpose:     Hashing Engine for Agentic State Persistence & Restart
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Agent Hasher R6 Class
#'
#' @description
#' Provides the infrastructure for high-performance state hashing and
#' node-level idempotency checks. This allows HydraR to replace external
#' dependencies like \code{targets} for dynamic agentic workflows.
#'
#' @importFrom R6 R6Class
#' @importFrom digest digest
#' @export
AgentHasher <- R6::R6Class("AgentHasher",
  public = list(
    #' @field db_path String. Path to the DuckDB hash registry.
    db_path = NULL,
    #' @field conn DBIConnection. Active connection to the registry.
    conn = NULL,

    #' @description Initialize the Hasher
    #' @param db_path String. Path to the DuckDB file.
    initialize = function(db_path = ":memory:") {
      self$db_path <- db_path
      self$conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
      self$.init_table()
    },

    #' @description Initialize the hash table
    .init_table = function() {
      DBI::dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS node_hashes (
          node_id VARCHAR,
          input_hash VARCHAR,
          logic_hash VARCHAR,
          output_json TEXT,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (node_id, input_hash, logic_hash)
        )
      ")
    },

    #' @description Calculate a unique hash for a node execution
    #' @param node AgentNode.
    #' @param state AgentState.
    #' @return A list containing input_hash and logic_hash.
    calculate_hashes = function(node, state) {
      # 1. Logic Hash (Function definition + Role)
      logic_content <- list(
        id = node$id,
        logic = if (inherits(node, "AgentLogicNode")) deparse(node$logic_fn) else node$role
      )
      logic_hash <- digest::digest(logic_content, algo = "md5")

      # 2. Input Hash (State variables consumed by the node)
      # For now, we hash the entire state, but this could be optimized to specific keys
      input_data <- state$get_all()
      input_hash <- digest::digest(input_data, algo = "md5")

      list(input_hash = input_hash, logic_hash = logic_hash)
    },

    #' @description Check if a node execution can be skipped
    #' @param node AgentNode.
    #' @param state AgentState.
    #' @return The cached output list if found, NULL otherwise.
    get_cached_output = function(node, state) {
      hashes <- self$calculate_hashes(node, state)
      
      res <- DBI::dbGetQuery(self$conn, "
        SELECT output_json FROM node_hashes 
        WHERE node_id = ? AND input_hash = ? AND logic_hash = ?
      ", params = list(node$id, hashes$input_hash, hashes$logic_hash))

      if (nrow(res) > 0) {
        return(jsonlite::fromJSON(res$output_json))
      }
      NULL
    },

    #' @description Store a successful node execution hash
    #' @param node AgentNode.
    #' @param state AgentState.
    #' @param output List. The node output to cache.
    store_hash = function(node, state, output) {
      hashes <- self$calculate_hashes(node, state)
      output_json <- jsonlite::toJSON(output)

      DBI::dbExecute(self$conn, "
        INSERT OR REPLACE INTO node_hashes (node_id, input_hash, logic_hash, output_json)
        VALUES (?, ?, ?, ?)
      ", params = list(node$id, hashes$input_hash, hashes$logic_hash, output_json))
    },

    #' @description Close the database connection
    finalize = function() {
      if (!is.null(self$conn)) DBI::dbDisconnect(self$conn, shutdown = TRUE)
    }
  )
)

# --- APAF Bioinformatics | hasher.R | Approved | 2026-04-16 ---

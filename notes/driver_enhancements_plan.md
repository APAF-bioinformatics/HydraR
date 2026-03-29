# HydraR Driver Architecture Enhancement Plan

> **Status**: Draft — Awaiting Approval  
> **Date**: 2026-03-29  
> **Approach**: Phased — Feature 1 first, then Feature 2, then Feature 3

---

## Overview

Three feature sets to evolve HydraR from a CLI-first orchestrator into a fully
hot-swappable, multi-backend distributed agent framework.

| Phase | Feature | Summary |
|-------|---------|---------|
| **F1** | CLI Parameter Options Slot | Structured `cli_opts` with per-driver schemas + warning/strict modes |
| **F2** | Hot-Swap Drivers & Distributed Simulation | `DriverRegistry`, runtime driver swaps, bi-directional message channels |
| **F3** | Cloud API Proxy Drivers | `httr2`-based HTTP drivers for OpenAI, Anthropic, Google Gemini API |

---

## Phase 1: CLI Parameter Options Slot

### 1.1 Problem

Each driver hard-codes its CLI arguments. There's no way for a node to pass
provider-specific flags like `--model gemini-2.5-pro`, `--output-format json`,
or `--yolo`.

### 1.2 Design Decision: Named List

A **named list** (not a string) is used because:

- Type-safe and inspectable (`cli_opts$model`)
- Composable with `purrr::imap` patterns
- No shell injection risk
- Can be validated against a per-driver schema

### 1.3 Per-Driver Schema with Warning/Strict Modes

Each driver defines a `supported_opts` character vector. A `validation_mode`
field controls behavior when unknown options are provided:

- `"warning"` (default): Issue a `warning()` for unrecognized options, pass them through
- `"strict"`: Issue a `stop()` for unrecognized options

### 1.4 CLI Flag Inventories (from `--help` output)

#### Gemini CLI (`gemini`)

```
Flag                          Type      Notes
-d, --debug                   boolean   Debug mode
-m, --model                   string    Model selection
-p, --prompt                  string    Non-interactive headless mode
-s, --sandbox                 boolean   Sandbox mode
-y, --yolo                    boolean   Auto-accept all actions
--approval-mode               choice    default|auto_edit|yolo|plan
--policy                      array     Policy files
--admin-policy                array     Admin policy files
--allowed-mcp-server-names    array     MCP server whitelist
--allowed-tools               array     Allowed tools (deprecated)
-e, --extensions              array     Extensions to use
-r, --resume                  string    Resume session
--include-directories         array     Extra workspace dirs
--screen-reader               boolean   Accessibility
-o, --output-format           choice    text|json|stream-json
--raw-output                  boolean   Disable output sanitization
--accept-raw-output-risk      boolean   Suppress raw-output warning
```

#### Claude CLI (`claude`)

```
Flag                          Type      Notes
--add-dir                     array     Extra allowed directories
--agent                       string    Agent for session
--agents                      json      Custom agents definition
--allowedTools                array     Allowed tools
--append-system-prompt        string    Append to system prompt
--betas                       array     Beta headers
--chrome                      boolean   Chrome integration
-c, --continue                boolean   Continue last conversation
--dangerously-skip-permissions boolean  Bypass permissions
-d, --debug                   string    Debug mode
--disable-slash-commands      boolean   Disable skills
--disallowedTools             array     Denied tools
--fallback-model              string    Fallback model
--input-format                choice    text|stream-json
--json-schema                 string    Structured output schema
--max-budget-usd              number    API spend cap
--mcp-config                  array     MCP server configs
--model                       string    Model selection
--no-session-persistence      boolean   Disable session save
--output-format               choice    text|json|stream-json
--permission-mode             choice    acceptEdits|bypassPermissions|default|delegate|dontAsk|plan
-p, --print                   boolean   Non-interactive output
--system-prompt               string    System prompt
--tools                       array     Available tools list
--verbose                     boolean   Verbose mode
```

#### Ollama CLI (`ollama run`)

```
Flag                          Type      Notes
-p, --parameter               key=val   Override model parameters (stackable)
                                        Common: num_ctx, temperature, top_p,
                                        top_k, repeat_penalty, seed, num_predict
(prompt as positional arg)    string    Direct prompt for one-shot
```

#### Copilot CLI (`gh copilot` / `copilot`)

```
Flag                          Type      Notes
--add-dir                     string    Extra allowed directory
--allow-all-paths             boolean   Disable path verification
--allow-all-tools             boolean   Allow all tools (no confirmation)
--allow-tool                  array     Allow specific tools
--deny-tool                   array     Deny specific tools
--model                       choice    claude-sonnet-4.5|claude-sonnet-4|gpt-5
-p, --prompt                  string    Non-interactive prompt
--resume                      string    Resume session
--screen-reader               boolean   Accessibility
--log-level                   choice    none|error|warning|info|debug|all|default
--no-custom-instructions      boolean   Disable AGENTS.md loading
```

### 1.5 Proposed Changes

#### [MODIFY] [driver.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver.R)

Add `cli_opts`, `supported_opts`, `validation_mode`, and `format_cli_opts()`:

```r
AgentDriver <- R6::R6Class("AgentDriver",
  public = list(
    id = NULL,
    supported_opts = character(0),   # Per-driver schema
    validation_mode = "warning",     # "warning" or "strict"

    initialize = function(id, validation_mode = "warning") {
      stopifnot(is.character(id) && length(id) == 1)
      stopifnot(validation_mode %in% c("warning", "strict"))
      self$id <- id
      self$validation_mode <- validation_mode
    },

    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      stop("Abstract Method: call() must be implemented by subclass.")
    },

    # Validate cli_opts against supported_opts schema
    validate_cli_opts = function(cli_opts) {
      if (length(cli_opts) == 0 || length(self$supported_opts) == 0) {
        return(invisible(TRUE))
      }
      unknown <- setdiff(names(cli_opts), self$supported_opts)
      if (length(unknown) > 0) {
        msg <- sprintf(
          "[%s] Unrecognized CLI option(s): %s. Supported: %s",
          self$id, paste(unknown, collapse = ", "),
          paste(self$supported_opts, collapse = ", ")
        )
        if (self$validation_mode == "strict") stop(msg)
        warning(msg)
      }
      invisible(TRUE)
    },

    # Convert named list to CLI arg vector
    format_cli_opts = function(cli_opts = list()) {
      if (length(cli_opts) == 0) return(character(0))
      self$validate_cli_opts(cli_opts)
      purrr::imap(cli_opts, function(val, key) {
        flag <- paste0("--", gsub("_", "-", key))
        if (is.logical(val) && val) return(flag)
        if (is.logical(val) && !val) return(character(0))
        if (is.character(val) && length(val) > 1) {
          # Array flags: repeat the flag for each value
          purrr::map(val, ~c(flag, .x)) |> unlist()
        } else {
          return(c(flag, as.character(val)))
        }
      }) |> unlist()
    }
  )
)
```

#### [MODIFY] [drivers_cli.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/drivers_cli.R)

Each driver gets a `supported_opts` vector and updated `call()`:

**GeminiCLIDriver** supported opts:
```r
supported_opts = c(
  "model", "sandbox", "yolo", "approval_mode", "policy",
  "admin_policy", "allowed_mcp_server_names", "allowed_tools",
  "extensions", "resume", "include_directories", "screen_reader",
  "output_format", "raw_output", "accept_raw_output_risk", "debug"
)
```

**ClaudeCodeDriver** supported opts:
```r
supported_opts = c(
  "add_dir", "agent", "agents", "allowedTools", "append_system_prompt",
  "betas", "continue", "dangerously_skip_permissions", "debug",
  "disallowedTools", "fallback_model", "input_format", "json_schema",
  "max_budget_usd", "mcp_config", "model", "output_format",
  "permission_mode", "print", "system_prompt", "tools", "verbose"
)
```

**OllamaDriver** supported opts:
```r
supported_opts = c(
  "num_ctx", "temperature", "top_p", "top_k",
  "repeat_penalty", "seed", "num_predict"
)
```

Note: Ollama uses `-p key=val` style rather than `--key val`, so
`format_cli_opts()` will be overridden:

```r
format_cli_opts = function(cli_opts = list()) {
  if (length(cli_opts) == 0) return(character(0))
  self$validate_cli_opts(cli_opts)
  # Ollama uses: -p key=value (stackable)
  purrr::imap(cli_opts, function(val, key) {
    c("-p", paste0(key, "=", val))
  }) |> unlist()
}
```

**CopilotCLIDriver** supported opts:
```r
supported_opts = c(
  "add_dir", "allow_all_paths", "allow_all_tools", "allow_tool",
  "deny_tool", "model", "prompt", "resume", "screen_reader",
  "log_level", "no_custom_instructions"
)
```

#### [MODIFY] [node_llm.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/node_llm.R)

Add `cli_opts` field to `AgentLLMNode`:

```r
#' @field cli_opts List. Default CLI options for the driver.
cli_opts = list(),

initialize = function(id, role, driver, model = NULL, cli_opts = list(),
                      prompt_builder = NULL, tools = list(), label = NULL) {
  # ... existing logic ...
  self$cli_opts <- cli_opts
},

run = function(state, ...) {
  # ... existing prompt construction ...
  raw_response <- self$driver$call(
    prompt = full_prompt,
    model = self$model,
    cli_opts = self$cli_opts,
    ...
  )
  # ... existing error handling ...
}
```

#### [MODIFY] [factory.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/factory.R)

Pass `cli_opts` through `add_llm_node()` and `dag_add_llm_node()`.

#### [NEW] test-cli_opts.R

Tests:
- Valid opts pass through without warning
- Unknown opts trigger warning in `"warning"` mode
- Unknown opts trigger error in `"strict"` mode
- `format_cli_opts()` produces correct arg vectors
- Ollama's `format_cli_opts()` override produces `-p key=val`
- Boolean flags emit flag-only (no value)

---

## Phase 2: Hot-Swappable Drivers & Distributed Simulation

### 2.1 Driver Registry

#### [NEW] [driver_registry.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver_registry.R)

Central `DriverRegistry` R6 class:

```r
DriverRegistry <- R6::R6Class("DriverRegistry",
  public = list(
    drivers = list(),

    register = function(driver) {
      stopifnot(inherits(driver, "AgentDriver"))
      self$drivers[[driver$id]] <- driver
      invisible(self)
    },

    get = function(id) {
      if (!id %in% names(self$drivers)) {
        stop(sprintf("Driver '%s' not found in registry.", id))
      }
      self$drivers[[id]]
    },

    swap = function(node, new_driver_id) {
      stopifnot(inherits(node, "AgentLLMNode"))
      node$driver <- self$get(new_driver_id)
      invisible(node)
    },

    list_drivers = function() names(self$drivers)
  )
)
```

### 2.2 Node-Level Hot-Swap

#### [MODIFY] [node_llm.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/node_llm.R)

Add `swap_driver()` convenience method:

```r
swap_driver = function(new_driver) {
  stopifnot(inherits(new_driver, "AgentDriver"))
  self$driver <- new_driver
  invisible(self)
}
```

### 2.3 Private Point-to-Point Messaging

> [!IMPORTANT]
> In a true distributed algorithm, message passing is **private** — a message
> sent from Node A to Node B should not be visible to Node C. A shared message
> board (broadcast model) is insecure and violates this invariant.

#### Design: Per-Node Private Mailboxes

Each node has a private inbox stored in `AgentState` under a namespaced key:
`__inbox__{node_id}__`. Messages are structured with `from`, `to`, and
`content` fields. Only the addressed recipient can read its own inbox.

```
State keys:
  __inbox__proposer__  →  [msg1, msg2, ...]   (only "proposer" reads this)
  __inbox__critic__    →  [msg3, msg4, ...]   (only "critic" reads this)
```

#### [NEW] [messaging.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/messaging.R)

Private messaging primitives:

```r
#' Generate the private inbox key for a node
#' @param node_id String. Target node ID.
#' @return String. The state key for this node's inbox.
#' \@export
inbox_key <- function(node_id) {
  paste0("__inbox__", node_id, "__")
}

#' Send a private message from one node to another
#'
#' Appends a message to the recipient's private inbox in the AgentState.
#' @param state AgentState object.
#' @param from String. Sender node ID.
#' @param to String. Recipient node ID.
#' @param content Any. The message payload.
#' @return The state (invisibly).
#' \@export
send_message <- function(state, from, to, content) {
  stopifnot(inherits(state, "AgentState"))
  stopifnot(is.character(from) && length(from) == 1)
  stopifnot(is.character(to) && length(to) == 1)

  key <- inbox_key(to)
  msg <- list(
    from = from,
    to = to,
    content = content,
    timestamp = Sys.time()
  )

  current <- state$get(key, default = list())
  state$set(key, c(current, list(msg)))
  invisible(state)
}

#' Read private messages from a node's inbox
#'
#' Only the addressed recipient should call this to read its own inbox.
#' Optionally filter by sender.
#' @param state AgentState object.
#' @param node_id String. The node reading its own inbox.
#' @param from String. Optional sender filter.
#' @return List of message objects.
#' \@export
read_messages <- function(state, node_id, from = NULL) {
  stopifnot(inherits(state, "AgentState"))
  key <- inbox_key(node_id)
  msgs <- state$get(key, default = list())
  if (!is.null(from)) {
    msgs <- purrr::keep(msgs, ~.x$from == from)
  }
  msgs
}

#' Clear a node's inbox (after processing)
#'
#' @param state AgentState object.
#' @param node_id String. The node clearing its inbox.
#' @return The state (invisibly).
#' \@export
clear_inbox <- function(state, node_id) {
  stopifnot(inherits(state, "AgentState"))
  state$set(inbox_key(node_id), list())
  invisible(state)
}
```

#### Access Control

The messaging API enforces a **convention-based** privacy model:

1. `send_message()` can only write to another node's inbox (never your own)
2. `read_messages()` should only be called by the node reading its own inbox
3. `prompt_builder` functions are scoped to their own node ID, so they
   naturally call `read_messages(state, self$id)` — not another node's ID

For stronger enforcement, a future version can add a `caller_id` parameter
that validates `node_id == caller_id` at read time.

#### Message Audit Logging

All messaging events (`send`, `read`, `clear`) are recorded to an append-only
audit log for observability, debugging, and replay. The `MessageLog` R6 class
supports three pluggable backends that mirror the existing `Checkpointer`
hierarchy:

| Backend | Storage | Use Case |
|---------|---------|----------|
| `MemoryMessageLog` | In-memory list | Unit tests, short runs |
| `RDSMessageLog` | `.rds` file on disk | Single-user, lightweight persistence |
| `DuckDBMessageLog` | `message_log` table in DuckDB | Production, queryable history |

##### [NEW] [message_log.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/message_log.R)

```r
MessageLog <- R6::R6Class("MessageLog",
  public = list(
    log = function(event_type, from, to, content = NULL, thread_id = NULL) {
      stop("Abstract: log() must be implemented by subclass.")
    },
    get_log = function(thread_id = NULL, from = NULL, to = NULL) {
      stop("Abstract: get_log() must be implemented by subclass.")
    }
  )
)

MemoryMessageLog <- R6::R6Class("MemoryMessageLog",
  inherit = MessageLog,
  public = list(
    entries = list(),

    log = function(event_type, from, to, content = NULL, thread_id = NULL) {
      entry <- list(
        event = event_type,  # "send", "read", "clear"
        from = from, to = to,
        content_preview = if (!is.null(content)) substr(as.character(content), 1, 200) else NA,
        thread_id = thread_id,
        timestamp = Sys.time()
      )
      self$entries <- c(self$entries, list(entry))
      invisible(self)
    },

    get_log = function(thread_id = NULL, from = NULL, to = NULL) {
      entries <- self$entries
      if (!is.null(thread_id)) entries <- purrr::keep(entries, ~identical(.x$thread_id, thread_id))
      if (!is.null(from)) entries <- purrr::keep(entries, ~identical(.x$from, from))
      if (!is.null(to)) entries <- purrr::keep(entries, ~identical(.x$to, to))
      entries
    }
  )
)

DuckDBMessageLog <- R6::R6Class("DuckDBMessageLog",
  inherit = MessageLog,
  public = list(
    con = NULL,
    table_name = "message_log",

    initialize = function(con = NULL, db_path = NULL, table_name = "message_log") {
      self$table_name <- table_name
      if (!is.null(db_path)) {
        if (!requireNamespace("duckdb", quietly = TRUE)) stop("duckdb package required.")
        self$con <- DBI::dbConnect(duckdb::duckdb(), db_path)
      } else if (!is.null(con)) {
        self$con <- con
      } else {
        stop("Either 'con' or 'db_path' must be provided.")
      }
      DBI::dbExecute(self$con, sprintf("
        CREATE TABLE IF NOT EXISTS %s (
          id INTEGER DEFAULT nextval('%s_seq'),
          event VARCHAR,
          from_node VARCHAR,
          to_node VARCHAR,
          content_preview VARCHAR,
          thread_id VARCHAR,
          timestamp TIMESTAMP DEFAULT current_timestamp
        )
      ", self$table_name, self$table_name))
    },

    log = function(event_type, from, to, content = NULL, thread_id = NULL) {
      preview <- if (!is.null(content)) substr(as.character(content), 1, 200) else NA
      DBI::dbExecute(self$con, sprintf("
        INSERT INTO %s (event, from_node, to_node, content_preview, thread_id)
        VALUES (?, ?, ?, ?, ?)
      ", self$table_name),
        params = list(event_type, from, to, preview, thread_id))
      invisible(self)
    },

    get_log = function(thread_id = NULL, from = NULL, to = NULL) {
      query <- sprintf("SELECT * FROM %s WHERE 1=1", self$table_name)
      params <- list()
      if (!is.null(thread_id)) { query <- paste(query, "AND thread_id = ?"); params <- c(params, thread_id) }
      if (!is.null(from)) { query <- paste(query, "AND from_node = ?"); params <- c(params, from) }
      if (!is.null(to)) { query <- paste(query, "AND to_node = ?"); params <- c(params, to) }
      query <- paste(query, "ORDER BY timestamp")
      DBI::dbGetQuery(self$con, query, params = params)
    }
  )
)
```

##### Integration with `send_message()` / `read_messages()` / `clear_inbox()`

The messaging functions accept an optional `message_log` parameter:

```r
send_message <- function(state, from, to, content, message_log = NULL, thread_id = NULL) {
  # ... existing inbox logic ...
  if (!is.null(message_log)) {
    message_log$log("send", from = from, to = to, content = content, thread_id = thread_id)
  }
  invisible(state)
}

read_messages <- function(state, node_id, from = NULL, message_log = NULL, thread_id = NULL) {
  # ... existing inbox logic ...
  if (!is.null(message_log)) {
    message_log$log("read", from = from %||% "*", to = node_id, thread_id = thread_id)
  }
  msgs
}

clear_inbox <- function(state, node_id, message_log = NULL, thread_id = NULL) {
  # ... existing logic ...
  if (!is.null(message_log)) {
    message_log$log("clear", from = NA, to = node_id, thread_id = thread_id)
  }
  invisible(state)
}
```

##### Usage

```r
# In-memory (default for tests)
log <- MemoryMessageLog$new()

# Or DuckDB (production — use existing master DB)
log <- DuckDBMessageLog$new(db_path = "~/.gemini/memory/bot_history.duckdb")

# Pass to messaging functions
send_message(state, "proposer", "critic", "My proposal...", message_log = log, thread_id = "debate_001")

# Query the log
log$get_log(thread_id = "debate_001", from = "proposer")
```

### 2.4 Distributed Simulation Pattern

With private messaging, a distributed algorithm simulation looks like:

```r
# Register heterogeneous drivers
registry <- DriverRegistry$new()
registry$register(GeminiCLIDriver$new())
registry$register(ClaudeCodeDriver$new())

# Build DAG with different drivers per node
dag <- AgentDAG$new()

# Proposer: reads its inbox for critic feedback, sends proposals to critic
dag$add_node(AgentLLMNode$new(
  id = "proposer",
  role = "Propose a solution. Read any feedback and revise.",
  driver = registry$get("gemini_cli"),
  prompt_builder = function(state) {
    topic <- state$get("topic")
    feedback <- read_messages(state, "proposer", from = "critic")
    last_feedback <- if (length(feedback) > 0) {
      feedback[[length(feedback)]]$content
    } else {
      "No feedback yet. Make an initial proposal."
    }
    sprintf("Topic: %s\nFeedback: %s", topic, last_feedback)
  }
))

# Critic: reads proposals from its inbox, sends feedback back to proposer
dag$add_node(AgentLLMNode$new(
  id = "critic",
  role = "Critique the proposal. Say APPROVED if satisfied.",
  driver = registry$get("claude_cli"),
  prompt_builder = function(state) {
    proposals <- read_messages(state, "critic", from = "proposer")
    last_proposal <- if (length(proposals) > 0) {
      proposals[[length(proposals)]]$content
    } else {
      "No proposal received."
    }
    sprintf("Proposal to review:\n%s", last_proposal)
  }
))

# Wire with message-passing logic nodes
dag$add_node(AgentLogicNode$new(
  id = "send_to_critic",
  logic_fn = function(state) {
    proposal <- state$get("proposer")  # Output from proposer node
    send_message(state, from = "proposer", to = "critic", content = proposal)
    list(status = "SUCCESS", output = NULL)
  }
))

dag$add_node(AgentLogicNode$new(
  id = "send_to_proposer",
  logic_fn = function(state) {
    critique <- state$get("critic")  # Output from critic node
    send_message(state, from = "critic", to = "proposer", content = critique)
    list(status = "SUCCESS", output = NULL)
  }
))

# Wire: proposer -> send_to_critic -> critic -> send_to_proposer -> (loop)
dag$add_edge("proposer", "send_to_critic")
dag$add_edge("send_to_critic", "critic")
dag$add_edge("critic", "send_to_proposer")

dag$add_conditional_edge("send_to_proposer",
  test = function(output) {
    # Check if critic approved — read from state
    !grepl("APPROVED", output %||% "")
  },
  if_true = "proposer",   # Loop back for revision
  if_false = NULL          # Stop — consensus reached
)
dag$set_start_node("proposer")

state <- AgentState$new(
  initial_data = list(topic = "Design a caching layer")
)

dag$run(state, max_steps = 20)
```

#### [NEW] test-driver_registry.R

Tests:
- Register and retrieve drivers
- Swap driver on a node at runtime
- Registry errors for unknown driver ID
- End-to-end DAG with mixed drivers (mocked)

#### [NEW] test-private_messaging.R

Tests:
- `send_message()` writes to recipient's inbox only
- `read_messages()` only returns messages for the addressed node
- `read_messages()` filters by sender correctly
- `clear_inbox()` empties a node's inbox
- Node A cannot read Node B's inbox (convention test)
- Bi-directional loop with 2 mock nodes converges via private messages
- Messages include timestamp metadata

---

## Phase 3: Cloud API Proxy Drivers

### 3.1 Dependency: `httr2`

- Added to `Suggests:` in DESCRIPTION (not Imports)
- Runtime check at API driver construction:

```r
initialize = function(...) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    msg <- "Package 'httr2' is required for API drivers. Install with: install.packages('httr2')"
    # Auto-install if in interactive session
    if (interactive()) {
      message(msg, "\nAttempting automatic installation...")
      utils::install.packages("httr2")
      if (!requireNamespace("httr2", quietly = TRUE)) stop(msg)
    } else {
      stop(msg)
    }
  }
  super$initialize(...)
}
```

### 3.2 Abstract API Driver

#### [NEW] [driver_api.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver_api.R)

```r
AgentAPIDriver <- R6::R6Class("AgentAPIDriver",
  inherit = AgentDriver,
  public = list(
    base_url = NULL,
    api_key_env = NULL,
    default_params = list(),

    initialize = function(id, base_url, api_key_env,
                          default_params = list(), validation_mode = "warning") {
      # httr2 runtime check (auto-install if interactive)
      if (!requireNamespace("httr2", quietly = TRUE)) {
        msg <- "Package 'httr2' required for API drivers. install.packages('httr2')"
        if (interactive()) {
          message(msg, "\nAttempting automatic installation...")
          utils::install.packages("httr2")
          if (!requireNamespace("httr2", quietly = TRUE)) stop(msg)
        } else {
          stop(msg)
        }
      }
      super$initialize(id, validation_mode)
      self$base_url <- base_url
      self$api_key_env <- api_key_env
      self$default_params <- default_params
    },

    get_api_key = function() {
      key <- Sys.getenv(self$api_key_env)
      if (nchar(key) == 0) stop(sprintf("API key not found: %s", self$api_key_env))
      key
    },

    build_request_body = function(prompt, model, params) {
      stop("Abstract: build_request_body() must be implemented.")
    },

    parse_response = function(resp_body) {
      stop("Abstract: parse_response() must be implemented.")
    },

    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      target_model <- if (!is.null(model)) model else self$default_params$model
      params <- utils::modifyList(self$default_params, cli_opts)
      body <- self$build_request_body(prompt, target_model, params)

      resp <- httr2::request(self$base_url) |>
        httr2::req_headers(
          "Authorization" = paste("Bearer", self$get_api_key()),
          "Content-Type" = "application/json"
        ) |>
        httr2::req_body_json(body) |>
        httr2::req_retry(max_tries = 3, backoff = ~2) |>
        httr2::req_perform()

      resp_body <- httr2::resp_body_json(resp)
      self$parse_response(resp_body)
    }
  )
)
```

### 3.3 Concrete API Drivers

#### [NEW] [drivers_api.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/drivers_api.R)

Three implementations:

| Driver | Endpoint | Auth | Key Env Var |
|--------|----------|------|-------------|
| `OpenAIAPIDriver` | `POST /v1/chat/completions` | `Bearer` header | `OPENAI_API_KEY` |
| `AnthropicAPIDriver` | `POST /v1/messages` | `x-api-key` header | `ANTHROPIC_API_KEY` |
| `GeminiAPIDriver` | `POST /v1beta/models/{model}:generateContent` | `?key=` query | `GOOGLE_API_KEY` |

Each overrides `build_request_body()` and `parse_response()` for the
provider-specific JSON schema. `AnthropicAPIDriver` and `GeminiAPIDriver`
also override `call()` for non-standard auth patterns.

The `cli_opts` list maps to API parameters (e.g., `temperature`, `max_tokens`,
`top_p`), validated against per-driver `supported_opts`.

#### [NEW] test-drivers_api.R

Tests (all mocked, no real API calls):
- Construction fails gracefully if `httr2` not installed
- `build_request_body()` produces correct JSON for each provider
- `parse_response()` extracts text correctly
- `cli_opts` are forwarded as API parameters
- Auth header construction for each provider style

---

## File Change Summary

### Phase 1 (CLI Options)

| File | Action |
|------|--------|
| [driver.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver.R) | MODIFY — `cli_opts`, `supported_opts`, `validation_mode`, `validate_cli_opts()`, `format_cli_opts()` |
| [drivers_cli.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/drivers_cli.R) | MODIFY — Each driver gets `supported_opts` + updated `call()` |
| [node_llm.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/node_llm.R) | MODIFY — `cli_opts` field |
| [factory.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/factory.R) | MODIFY — Pass `cli_opts` through helpers |
| test-cli_opts.R | NEW — Schema validation + formatting tests |

### Phase 2 (Hot-Swap & Distributed)

| File | Action |
|------|--------|
| [driver_registry.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver_registry.R) | NEW — `DriverRegistry` R6 class |
| [messaging.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/messaging.R) | NEW — `send_message()`, `read_messages()`, `clear_inbox()`, `inbox_key()` |
| [message_log.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/message_log.R) | NEW — `MessageLog`, `MemoryMessageLog`, `DuckDBMessageLog` |
| [node_llm.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/node_llm.R) | MODIFY — `swap_driver()` method |
| test-driver_registry.R | NEW |
| test-private_messaging.R | NEW |
| test-message_log.R | NEW — Audit logging tests (memory + DuckDB backends) |

### Phase 3 (API Proxy)

| File | Action |
|------|--------|
| [driver_api.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/driver_api.R) | NEW — `AgentAPIDriver` base |
| [drivers_api.R](file:///Users/ignatiuspang/Workings/2026/HydraR/R/drivers_api.R) | NEW — OpenAI, Anthropic, Gemini |
| DESCRIPTION | MODIFY — `httr2` in Suggests |
| NAMESPACE | MODIFY — Export new classes |
| test-drivers_api.R | NEW |

---

## Verification Plan (per phase)

### Phase 1
- `devtools::test(filter = "cli_opts")` — all new tests pass
- `devtools::test()` — all existing tests still pass (backward compat)
- Manual: `GeminiCLIDriver$new(validation_mode = "strict")$call("Hello", cli_opts = list(output_format = "json"))`

### Phase 2
- `devtools::test(filter = "driver_registry|message_channels")` — new tests pass
- Manual: Build a 2-node debate DAG with Gemini + Claude, confirm loop converges

### Phase 3
- `devtools::test(filter = "drivers_api")` — mocked API tests pass
- `devtools::check()` — zero errors/warnings/notes
- Manual: `OpenAIAPIDriver$new()$call("Hello")` with valid OPENAI_API_KEY

<!-- APAF Bioinformatics | driver_enhancements_plan.md | Approved | 2026-03-29 -->

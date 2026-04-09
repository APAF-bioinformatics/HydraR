# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        node_languages.R
# Author:      APAF Agentic Workflow
# Purpose:     System Execution Nodes (Bash, Python)
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' @include node.R
NULL

#' Bash Execution Node
#'
#' @description
#' Executes a raw bash script. Can run within an isolated worktree if configured.
#'
#' @return An `AgentBashNode` object.
#' @examples
#' \dontrun{
#' node <- AgentBashNode$new(id = "bash_1")
#' node$call("echo hello")
#' }
#' @export
AgentBashNode <- R6::R6Class("AgentBashNode",
  inherit = AgentNode,
  public = list(
    #' @field script Character string or Function. The bash script to execute.
    script = NULL,
    #' @field env_vars Named list. Environment variables to inject.
    env_vars = NULL,

    #' @description Initialize Bash Node
    #' @param id Node ID
    #' @param label Node Label
    #' @param script String or Function(state) returning a string.
    #' @param env_vars Named list of environment variables
    #' @param params List of standard Node parameters
    initialize = function(id, label = NULL, script, env_vars = list(), params = list()) {
      super$initialize(id, label, params)
      stopifnot(is.character(script) || is.function(script))
      self$script <- script
      self$env_vars <- env_vars
    },

    #' Run Bash Execution
    #' @param state AgentState object.
    #' @param working_dir Directory context for execution.
    #' @return List with output, status_code, and success flag.
    run = function(state, working_dir = NULL) {
      script_content <- if (is.function(self$script)) {
        self$script(state)
      } else {
        self$script
      }

      exec_dir <- working_dir %||% getwd()

      tmp_script <- tempfile(fileext = ".sh", tmpdir = exec_dir)
      writeLines(script_content, tmp_script)
      Sys.chmod(tmp_script, mode = "0755")
      on.exit(if (file.exists(tmp_script)) unlink(tmp_script), add = TRUE)

      env_vec <- if (length(self$env_vars) > 0) {
        paste(names(self$env_vars), unlist(self$env_vars), sep = "=")
      } else {
        character()
      }

      withr::with_dir(exec_dir, {
        res <- system2("bash", args = basename(tmp_script), stdout = TRUE, stderr = TRUE, env = env_vec)
        status_code <- attr(res, "status")
        if (is.null(status_code)) status_code <- 0
      })

      list(
        output = paste(res, collapse = "\n"),
        status_code = status_code,
        success = status_code == 0
      )
    }
  )
)

#' Python Execution Node
#'
#' @description
#' Executes a python script via system python or reticulate.
#'
#' @return An `AgentPythonNode` object.
#' @examples
#' \dontrun{
#' node <- AgentPythonNode$new(id = "py_1")
#' node$call("print('hello')")
#' }
#' @export
AgentPythonNode <- R6::R6Class("AgentPythonNode",
  inherit = AgentNode,
  public = list(
    #' @field script Character string or Function. The python script to execute.
    script = NULL,
    #' @field engine Character. Execution engine ("system2" or "reticulate").
    engine = NULL,

    #' @param id Node ID
    #' @param label Node Label
    #' @param script String or Function(state) returning a string.
    #' @param engine "system2" (isolated process) or "reticulate" (inline bindings).
    #' @param params List of standard Node parameters
    initialize = function(id, label = NULL, script, engine = "system2", params = list()) {
      super$initialize(id, label, params)
      stopifnot(is.character(script) || is.function(script))
      stopifnot(engine %in% c("system2", "reticulate"))
      self$script <- script
      self$engine <- engine

      if (engine == "reticulate") {
        if (!requireNamespace("reticulate", quietly = TRUE)) {
          stop("The 'reticulate' package must be installed to use engine='reticulate'.")
        }
      }
    },

    #' Run Python Execution
    #' @param state AgentState object.
    #' @param working_dir Directory context for execution.
    #' @return List with output, success flag, and optionally result variables.
    run = function(state, working_dir = NULL) {
      script_content <- if (is.function(self$script)) {
        self$script(state)
      } else {
        self$script
      }

      exec_dir <- working_dir %||% getwd()

      if (self$engine == "system2" || self$engine == "reticulate") {
        # Both engines write temporary JSON to marshal state safely
        tmp_json <- tempfile(fileext = ".json", tmpdir = exec_dir)
        jsonlite::write_json(state$get_all(), tmp_json, auto_unbox = TRUE)
        on.exit(
          {
            if (file.exists(tmp_json)) unlink(tmp_json)
          },
          add = TRUE
        )
      }

      if (self$engine == "system2") {
        tmp_script <- tempfile(fileext = ".py", tmpdir = exec_dir)
        writeLines(script_content, tmp_script)
        on.exit(
          {
            if (file.exists(tmp_script)) unlink(tmp_script)
          },
          add = TRUE
        )

        # Execute using system2
        withr::with_dir(exec_dir, {
          # Provide the json state via argument 1
          res <- system2("python3", args = c(basename(tmp_script), basename(tmp_json)), stdout = TRUE, stderr = TRUE)
          status_code <- attr(res, "status")
          if (is.null(status_code)) status_code <- 0
        })

        list(
          output = paste(res, collapse = "\n"),
          status_code = status_code,
          success = status_code == 0
        )
      } else {
        withr::with_dir(exec_dir, {
          # Inject state loading preamble to user script
          # Normalizes path separators for python
          safe_json_path <- gsub("\\\\", "/", tmp_json)
          preamble <- sprintf("import json\nwith open('%s', 'r') as f:\n    state_r = json.load(f)\n\n", safe_json_path)
          full_script <- paste0(preamble, script_content)

          # Initialize err
          err <- NULL
          output <- capture.output({
            tryCatch(
              {
                reticulate::py_run_string(full_script)
              },
              error = function(e) {
                err <<- e$message
              }
            )
          })

          result_val <- NULL
          py_obj <- reticulate::py
          if ("result" %in% names(py_obj) && is.null(err)) {
            tryCatch(
              {
                result_val <- py_obj$result
              },
              error = function(e) {}
            )
          }

          list(
            output = paste(output, collapse = "\n"),
            result = result_val,
            error = err,
            success = is.null(err)
          )
        })
      }
    }
  )
)

#' <!-- APAF Bioinformatics | node_languages.R | Approved | 2026-03-29 -->

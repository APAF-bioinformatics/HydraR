# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-fan-out-fan-in.R
# Author:      APAF Agentic Workflow
# Purpose:     Test for Fan-Out and Fan-In Synthesis Scenario
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

library(testthat)
library(HydraR)

# Mock Driver for testing LLM nodes
MockFanOutDriver <- R6::R6Class("MockFanOutDriver",
  inherit = AgentDriver,
  public = list(
    call = function(prompt, ...) {
      if (grepl("creative director", prompt)) {
         return("The cybernetic cat enters the hidden city.")
      } else if (grepl("action-thriller", prompt)) {
         return("Explosions in the neon alleyway!")
      } else if (grepl("mystery writer", prompt)) {
         return("Who left this cryptic holodisk?")
      } else if (grepl("romance writer", prompt)) {
         return("The cat shared a tender moment with a drone.")
      } else if (grepl("master editor", prompt)) {
         return("The final story: Action, Mystery, and Romance combined.")
      }
      return("Default mock response")
    }
  )
)

test_that("Fan-Out Fan-In YAML workflow loads and executes correctly", {
  # 1. We read the actual vignette yaml to ensure it's valid
  yaml_path <- file.path("..", "..", "vignettes", "fan_out_fan_in.yml")

  # Fallback for devtools::test() vs R CMD check paths
  if (!file.exists(yaml_path)) {
    yaml_path <- file.path("..", "vignettes", "fan_out_fan_in.yml")
  }
  if (!file.exists(yaml_path)) {
    yaml_path <- file.path(Sys.getenv("R_PACKAGE_SOURCE", "."), "vignettes", "fan_out_fan_in.yml")
  }

  skip_if_not(file.exists(yaml_path), "fan_out_fan_in.yml not found. Skipping test.")

  # Load the workflow
  wf <- load_workflow(yaml_path)

  # Validate the structure of the loaded workflow
  expect_true(is.character(wf$graph))
  expect_true(is.list(wf$initial_state))
  expect_equal(wf$initial_state$premise, "A cybernetic cat discovers a hidden underground city.")

  # 2. Inject Mock Driver into the registry so the factory picks it up
  drv_registry <- get_driver_registry()
  drv_registry$register("gemini", MockFanOutDriver$new())

  # 3. Create and compile DAG using the standard auto_node_factory
  dag <- spawn_dag(wf, auto_node_factory(driver_registry = drv_registry))
  expect_silent(dag$compile())

  # Ensure the graph has the right structure
  expect_true(igraph::is_dag(dag$graph))
  expect_equal(length(dag$nodes), 5)
  expect_equal(length(igraph::E(dag$graph)), 6) # 3 fan-out + 3 fan-in edges

  # 4. Run DAG
  # Suppressing print messages from DAG execution
  capture.output({
    result <- dag$run(initial_state = wf$initial_state)
  })

  # 5. Assertions
  expect_equal(result$status, "completed")
  expect_equal(result$state$get("director"), "The cybernetic cat enters the hidden city.")
  expect_equal(result$state$get("writer_action"), "Explosions in the neon alleyway!")
  expect_equal(result$state$get("writer_mystery"), "Who left this cryptic holodisk?")
  expect_equal(result$state$get("writer_romance"), "The cat shared a tender moment with a drone.")
  expect_equal(result$state$get("editor"), "The final story: Action, Mystery, and Romance combined.")

  # Ensure execution order: director -> writers -> editor
  traces <- result$trace_log
  expect_true(!is.null(traces))

  # The editor should be the last node executed
  executed_nodes <- purrr::map_chr(traces, ~ .x$node)
  expect_equal(tail(executed_nodes, 1), "editor")
  expect_equal(head(executed_nodes, 1), "director")
})

# <!-- APAF Bioinformatics | test-fan-out-fan-in.R | Approved | 2026-03-31 -->

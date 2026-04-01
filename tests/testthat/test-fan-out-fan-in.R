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
  # Inline definition of the YAML to ensure robustness across R CMD check environments
  yaml_content <- "
graph: |
  graph TD
    director[\"Director | type=llm | role_id=director | driver=gemini | prompt_id=prompt_director\"]
    writer_action[\"Action Writer | type=llm | role_id=writer_action | driver=gemini | prompt_id=prompt_action\"]
    writer_mystery[\"Mystery Writer | type=llm | role_id=writer_mystery | driver=gemini | prompt_id=prompt_mystery\"]
    writer_romance[\"Romance Writer | type=llm | role_id=writer_romance | driver=gemini | prompt_id=prompt_romance\"]
    editor[\"Master Editor | type=llm | role_id=editor | driver=gemini | prompt_id=prompt_editor\"]

    director --> writer_action
    director --> writer_mystery
    director --> writer_romance

    writer_action --> editor
    writer_mystery --> editor
    writer_romance --> editor

roles:
  director: \"You are the creative director setting the stage.\"
  writer_action: \"You are an action-thriller writer. Write a short, fast-paced scene.\"
  writer_mystery: \"You are a mystery writer. Write a short, suspenseful scene.\"
  writer_romance: \"You are a romance writer. Write a short, emotional scene.\"
  editor: \"You are the master editor. Combine the scenes into a cohesive short story.\"

logic:
  prompt_director: >
    sprintf(\"Expand slightly on this premise: %s\", state$get(\"premise\"))

  prompt_action: >
    sprintf(\"Based on the director's vision: %s\\nWrite an action scene.\", state$get(\"director\"))

  prompt_mystery: >
    sprintf(\"Based on the director's vision: %s\\nWrite a mystery scene.\", state$get(\"director\"))

  prompt_romance: >
    sprintf(\"Based on the director's vision: %s\\nWrite a romantic or emotional scene.\", state$get(\"director\"))

  prompt_editor: >
    sprintf(
      \"Synthesize these three scenes into one short story:\\n\\nAction: %s\\n\\nMystery: %s\\n\\nRomance: %s\",
      state$get(\"writer_action\"),
      state$get(\"writer_mystery\"),
      state$get(\"writer_romance\")
    )

start_node: director

initial_state:
  premise: \"A cybernetic cat discovers a hidden underground city.\"
"

  yaml_path <- tempfile(fileext = ".yml")
  writeLines(yaml_content, yaml_path)

  # Load the workflow from the temp file
  wf <- load_workflow(yaml_path)

  # Validate the structure of the loaded workflow
  expect_true(is.character(wf$graph))
  expect_true(is.list(wf$initial_state))
  expect_equal(wf$initial_state$premise, "A cybernetic cat discovers a hidden underground city.")

  # Inject Mock Driver into the registry so the factory picks it up
  drv_registry <- get_driver_registry()
  drv_registry$register("gemini", MockFanOutDriver$new())

  # Create and compile DAG using the standard auto_node_factory
  dag <- spawn_dag(wf, auto_node_factory(driver_registry = drv_registry))
  expect_silent(dag$compile())

  # Ensure the graph has the right structure
  expect_true(igraph::is_dag(dag$graph))
  expect_equal(length(dag$nodes), 5)
  expect_equal(length(igraph::E(dag$graph)), 6) # 3 fan-out + 3 fan-in edges

  # Run DAG
  # Suppressing print messages from DAG execution
  capture.output({
    result <- dag$run(initial_state = wf$initial_state)
  })

  # Assertions
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

  unlink(yaml_path)
})

# <!-- APAF Bioinformatics | test-fan-out-fan-in.R | Approved | 2026-03-31 -->

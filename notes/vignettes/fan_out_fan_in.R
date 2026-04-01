## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(HydraR)

## ----load_wf------------------------------------------------------------------
# # 1. Load the workflow definitions into the registries
# wf <- load_workflow("fan_out_fan_in.yml")
# 
# # 2. Compile the Directed Acyclic Graph
# dag <- spawn_dag(wf, auto_node_factory())

## ----running------------------------------------------------------------------
# # Execute with the initial premise extracted from the YAML file
# res <- dag$run(initial_state = wf$initial_state)
# 
# # View the final synthesized story
# cat(res$results$editor$output)

## ----results='asis'-----------------------------------------------------------
# cat("```mermaid\n")
# cat(dag$plot(type = "mermaid", details = TRUE))
# cat("\n```\n")


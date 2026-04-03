## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = TRUE
)
library(HydraR)

## ----load---------------------------------------------------------------------
library(HydraR)

# Load the shopping assistant workflow
wf <- load_workflow("customer_agent.yml")

# Spawn and compile the DAG
dag <- spawn_dag(wf)

## ----plot---------------------------------------------------------------------
dag$plot()

## ----run, eval = FALSE--------------------------------------------------------
# # Note: Requires a valid GEMINI_API_KEY
# final <- dag$run(wf$initial_state, max_steps = 10)
# 
# # Display the final shopping journey result
# cat("Final Recommendation:", final$state$get("Shopper"), "\n")
# cat("User Feedback:", final$state$get("UserProxy"), "\n")


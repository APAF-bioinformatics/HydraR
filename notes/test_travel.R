library(HydraR)
setwd("vignettes")
wf <- load_workflow("hong_kong_travel.yml")
dag <- spawn_dag(wf, auto_node_factory())
results <- dag$run(
  initial_state = append(wf$initial_state, list(
    force_regenerate_images = FALSE, 
    aspect_ratio = "16:9"
  )), 
  max_steps = 15
)
print(paste("Status:", results$status))

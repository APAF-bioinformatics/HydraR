devtools::load_all(".")
library(HydraR)

# Initialize the Gemini CLI driver
driver <- GeminiCLIDriver$new()

# Define initial state
initial_state <- list(
    origin = "Sydney",
    destination = "Hong Kong",
    departure_date = "2026-05-26",
    return_date = "2026-06-01",
    airline = "Qantas",
    must_include = c("Cheung Chau Island", "Spaghetti House", "Local Cuisine"),
    itinerary_draft = NULL,
    validation_passed = FALSE
)

# 1. The Planner Node
planner_node <- AgentLLMNode$new(
    id = "TravelPlanner",
    label = "Gemini Itinerary Engine",
    role = "You are a professional travel concierge specializing in premium Hong Kong travel.",
    driver = driver,
    prompt_builder = function(state) {
        sprintf(
            "Plan a 3-day trip from %s to %s. 
            Dates: %s to %s. 
            Airline: %s. 
            Must include: %s. 
            Provide a detailed itinerary in Hong Kong.",
            state$get("origin"),
            state$get("destination"),
            state$get("departure_date"),
            state$get("return_date"),
            state$get("airline"),
            paste(state$get("must_include"), collapse = ", ")
        )
    }
)

# 2. The Auditor Node
auditor_node <- AgentLogicNode$new(
    id = "Auditor",
    label = "Constraint Validator",
    logic_fn = function(state) {
        itinerary <- state$get("TravelPlanner") # From the previous LLM node
        if (is.null(itinerary)) itinerary <- ""
        cat(sprintf("\n[Auditor] Inspecting itinerary: %s\n", substr(itinerary, 1, 100)))
        must_include <- state$get("must_include")

        # Simple string matching to check constraints
        found <- sapply(must_include, function(x) grepl(x, itinerary, ignore.case = TRUE))
        found_vec <- unlist(found)

        if (all(found_vec)) {
            cat("[Auditor] All constraints met!\n")
            list(
                status = "SUCCESS",
                output = list(validation_passed = TRUE, message = "All constraints met!")
            )
        } else {
            missing <- must_include[!found_vec]
            cat(sprintf("[Auditor] Missing items: %s\n", paste(missing, collapse = ", ")))
            list(
                status = "SUCCESS",
                output = list(
                    validation_passed = FALSE,
                    message = paste("Missing items:", paste(missing, collapse = ", "))
                )
            )
        }
    }
)

# Build DAG
dag <- AgentDAG$new()
dag$add_node(planner_node)
dag$add_node(auditor_node)

dag$add_edge("TravelPlanner", "Auditor")

# Conditional loop: Back to planner if validation fails
dag$add_conditional_edge(
    from = "Auditor",
    test = function(out) isTRUE(out$validation_passed),
    if_true = NULL, # END
    if_false = "TravelPlanner"
)

dag$set_start_node("TravelPlanner")
compiled_dag <- dag$compile()

# Execution
results <- compiled_dag$run(initial_state = initial_state, max_steps = 5)

# Display final itinerary
cat("\n\n=== Final Itinerary ===\n\n")
cat(results$state$get("TravelPlanner"))
cat("\n\n")

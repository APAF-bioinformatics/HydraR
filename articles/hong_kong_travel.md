# Agentic Travel Planning: Sydney to Hong Kong

## Introduction

This vignette demonstrates how to use `HydraR` to orchestrate a
high-fidelity travel planning workflow. Unlike simple mock-based agents,
we will use the `GeminiCLIDriver` to drive real-world logic transitions,
state management, and persistence for a complex itinerary.

We will plan a trip from **Sydney (SYD)** to **Hong Kong (HKG)** with
specific airline and activity constraints.

## Scenario Requirements

- **Route**: Sydney to Hong Kong (Departure: 29th May 2026, Return: 5th
  June 2026).
- **Airline**: Qantas (Required).
- **Activities**: Visit Cheung Chau Island, dine at Spaghetti House, and
  sample local Cantonese cuisine.
- **Goal**: Generate a structured 3-day itinerary that respects these
  constraints.

## Setup

First, load the library and initialize the `GeminiCLIDriver`.

``` r
library(HydraR)

# Initialize the Gemini CLI driver
# Note: This assumes the 'gemini' CLI is installed and configured on your system.
driver <- GeminiCLIDriver$new()
```

## Defining the Agent State

We define the initial state, which includes our hard constraints and
preferences.

``` r
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

state <- AgentState$new(initial_state)
```

## Defining the Logic Registry

To keep our architecture clean, we store complex R functions (like
prompts and validation logic) in a central registry. This allows the
Mermaid graph to focus on the structure and metadata.

``` r
travel_logic_registry <- list(
  # 1. The itinerary generation prompt
  plan_itinerary = function(state) {
    sprintf(
      "Plan a 3-day trip from %s to %s. Dates: %s to %s. Airline: %s. Must include: %s.",
      state$get("origin"), state$get("destination"),
      state$get("departure_date"), state$get("return_date"),
      state$get("airline"), paste(state$get("must_include"), collapse = ", ")
    )
  },

  # 2. The constraint validation logic
  validate_constraints = function(state) {
    itinerary <- state$get("Planner") %||% ""
    must_include <- state$get("must_include")
    found <- sapply(must_include, function(x) grepl(x, itinerary, ignore.case = TRUE))

    if (all(found)) {
      list(status = "SUCCESS", output = list(validation_passed = TRUE))
    } else {
      missing <- must_include[!found]
      list(status = "SUCCESS", output = list(
        validation_passed = FALSE,
        message = paste("Missing:", paste(missing, collapse = ", "))
      ))
    }
  }
)
```

## Defining the Workflow (Mermaid-as-Source)

We define the entire orchestration using Mermaid syntax. Parameters like
`role` and `driver` are baked directly into the graph.

``` r
mermaid_src <- '
graph TD
  Planner["Travel Planner | role=Travel Concierge | driver=gemini | prompt_id=plan_itinerary | workdir=./hkg_trip"]
  Auditor["Constraint Validator | logic_id=validate_constraints | retries=3"]

  Planner --> Auditor
  Auditor -- "fail" --> Planner
'
```

## Instantiating the DAG

We use a **Node Factory** to resolve the IDs in the Mermaid string
against our logic registry.

``` r
# The factory maps Mermaid params to HydraR Node objects
travel_node_factory <- function(id, label, params) {
  if (id == "Planner") {
    # Resolve driver from Mermaid params
    driver_obj <- if (params$driver == "gemini") {
      GeminiCLIDriver$new()
    } else {
      # Fallback or other drivers (Claude, OpenAI)
      NULL
    }

    return(AgentLLMNode$new(
      id = id, label = label,
      role = params$role,
      driver = driver_obj,
      prompt_builder = travel_logic_registry[[params$prompt_id]],
      params = params
    ))
  } else if (id == "Auditor") {
    return(AgentLogicNode$new(
      id = id, label = label,
      logic_fn = travel_logic_registry[[params$logic_id]],
      params = params
    ))
  }
}

# Create the DAG directly from the visual source
dag <- mermaid_to_dag(mermaid_src, travel_node_factory)
dag$compile()
#> Warning in dag$compile(): The graph contains cycles and no conditional edges
#> are defined. Linear execution may fail.
#> Warning in dag$compile(): Potential infinite loop detected: graph contains
#> cycles. Ensure conditional edges have exit conditions.
#> Graph compiled successfully.
```

## Visualizing the Workflow

We can view the agent’s logic directly using Mermaid.js syntax. By
setting `details = TRUE`, we see the embedded configuration parameters.

``` r
cat("```mermaid\n")
```

``` mermaid
``` r
cat(dag$plot(type = "mermaid", details = TRUE))
```

graph TD Planner\[“Travel Planner \| role=Travel Concierge \|
driver=gemini \| prompt_id=plan_itinerary \| workdir=./hkg_trip”\]
Auditor\[“Constraint Validator \| logic_id=validate_constraints \|
retries=3”\] Planner –\> Auditor Auditor – “fail” –\> Planner graph TD
Planner\[“Travel Planner \| role=Travel Concierge \| driver=gemini \|
prompt_id=plan_itinerary \| workdir=./hkg_trip”\] Auditor\[“Constraint
Validator \| logic_id=validate_constraints \| retries=3”\] Planner –\>
Auditor Auditor – “fail” –\> Planner

``` r
cat("\n```\n")
```

    ## Execution

    When we run the DAG, `HydraR` manages the state transitions and LLM calls. The `workdir` and `role` parameters are automatically applied.


    ``` r
    # Register a checkpointer for durability
    checkpointer <- DuckDBSaver$new(path = "travel_booking.duckdb")
    dag$set_checkpointer(checkpointer)

    # Run the orchestration
    results <- dag$run(initial_state = initial_state, max_steps = 5)

    # Display final itinerary
    cat(results$state$get("Planner"))

## Conclusion

This workflow demonstrates how `HydraR` provides: 1. **Dynamic
Prompting**: Injecting complex R state into LLM calls. 2.
**Reliability**: Using logic nodes as “guardrails” for non-deterministic
LLM output. 3. **Persistence**: The ability to checkpoint and resume
complex multi-step planning.

------------------------------------------------------------------------

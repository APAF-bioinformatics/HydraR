# Agentic Travel Planning: Sydney to Hong Kong

``` r

# Toggle for slow/expensive and potentially rate-limited AI figure generation
# Set to TRUE to force-regenerate the images, otherwise uses existing ones.
FORCE_REGENERATE_IMAGES <- FALSE
ASPECT_RATIO <- "16:9"


## If you want to regenerate the images, you'll need to turn FORCE_REGENERATE_IMAGES to TRUE
## and also set the GEMINI_API_KEY environment variable in .Renviron file.
```

## Introduction

This vignette demonstrates the **Zero-R-Code** orchestration pattern
using `HydraR`. Instead of defining roles, logic, and state in R blocks,
we define the entire workflow in a single `workflow.yml` file.

The R environment acts purely as an **interpreter/compiler** for the
language-independent manifest.

## Setup

First, load the HydraR library.

``` r

library(HydraR)
```

## Loading the Workflow (Declarative YAML)

We use
[`load_workflow()`](https://github.com/APAF-bioinformatics/HydraR/reference/load_workflow.md)
to ingest the entire definition from `hong_kong_travel.yml`. This file
contains the: 1. **Mermaid Graph** (Source of truth for DAG
architecture) 2. **LLM Roles** (System prompts for travel concierges) 3.
**Anonymous Logic** (R snippets for constraints and prompting) 4.
**Initial State** (Pre-configurations for the journey)

``` r

# Load everything from the external declarative source
wf <- load_workflow("hong_kong_travel.yml")
```

## Instantiating the DAG

With the registries populated by the loader, we simply pass the graph
and the universal
[`auto_node_factory()`](https://github.com/APAF-bioinformatics/HydraR/reference/auto_node_factory.md)
to
[`mermaid_to_dag()`](https://github.com/APAF-bioinformatics/HydraR/reference/mermaid_to_dag.md).

``` r

dag <- spawn_dag(wf, auto_node_factory())
```

## Visualizing the Workflow

We can view the agent’s logic directly using Mermaid.js syntax.

``` r

cat("```mermaid\n")
cat(dag$plot(type = "mermaid", details = TRUE))
cat("\n```\n")
```

## Execution

When we run the DAG, we use the `initial_state` extracted from the YAML
file. No manual R list creation is required.

``` r

# Register a checkpointer for durability
checkpointer <- DuckDBSaver$new(db_path = "travel_booking.duckdb")

# Run the orchestration using the state from YAML
results <- dag$run(
  initial_state = append(wf$initial_state, list(
    force_regenerate_images = FORCE_REGENERATE_IMAGES,
    aspect_ratio = ASPECT_RATIO
  )),
  max_steps = 15,
  checkpointer = checkpointer
)

# Display final itinerary
cat("\n\n### Generated Itinerary\n")
#>
#>
#> ### Generated Itinerary
cat(as.character(results$state$get("Planner")))
#> ## Sydney to Hong Kong: A 7-Day Cultural & Culinary Escape
#> **Travel Dates:** May 26, 2026 – June 1, 2026
#> **Airline:** Qantas (Direct flight SYD-HKG)
#>
#> This itinerary balances Hong Kong’s high-energy urban landscape with the tranquil, traditional charm of the outlying islands.
#>
#> ---
#>
#> ### **Day 1: Arrival & The Harbor Glow (May 26)**
#> *   **Arrival:** Land at HKG via Qantas. Take the Airport Express to Central.
#> *   **Check-in:** Stay in **Central or Sheung Wan** for the best access to transportation.
#> *   **Evening:** Walk the **Tsim Sha Tsui Promenade**. Take the Star Ferry across the harbor at sunset to see the city lights spark to life.
#> *   **Dinner:** **The Spaghetti House (TST Branch)** – A local Hong Kong institution. Enjoy their signature fusion pasta dishes that have been a city staple for decades.
#>
#> ### **Day 2: The Peak & Colonial History (May 27)**
#> *   **Morning:** Take the **Peak Tram** to Victoria Peak for the iconic skyline panorama. Walk the Lugard Road circular path.
#> *   **Lunch:** Dim Sum at **Luk Yu Tea House** (Central) – one of the oldest and most traditional tea houses in Hong Kong.
#> *   **Afternoon:** Explore the **Man Mo Temple** and wander the antique shops of **Cat Street**.
#> *   **Dinner:** Enjoy authentic Cantonese Roast Goose at **Yat Lok** (Michelin-starred, no-frills).
#>
#> ### **Day 3: The Slow Life – Cheung Chau Island (May 28)**
#> *   **Morning:** Take a ferry from **Central Pier 5** to Cheung Chau (approx. 45-60 mins).
#> *   **Activities:** Rent a bicycle and ride around the island’s northern and southern loops. Visit the **Pak Tai Temple** and hike to the **Mini Great Wall** for coastal views.
#> *   **Lunch:** Seafood street food. You must try the **Giant Fishball** and the **Mango Mochi**—both local island specialties.
#> *   **Dinner:** Dine at one of the open-air seafood restaurants along the **Cheung Chau Praya**. Pick a live fish from the tanks and have it steamed with ginger and scallion.
#>
#> ### **Day 4: Markets & Street Food Exploration (May 29)**
#> *   **Morning:** Head to **Mong Kok**. Wander the **Goldfish Market** and the **Flower Market**.
#> *   **Lunch:** **Tim Ho Wan** (The original dim sum specialist). Expect a queue, but it’s well worth the wait for the baked BBQ pork buns.
#> *   **Afternoon:** Explore the **Ladies' Market** and the **Temple Street Night Market** (as it sets up).
#> *   **Dinner:** Street food crawl in **Jordan/Mong Kok**. Try *Curry Fish Balls, Stinky Tofu (if you're brave!), and Pineapple Bun with butter* from a local *cha chaan teng*.
#>
#> ### **Day 5: Lantau Island & The Giant Buddha (May 30)**
#> *   **Morning:** Take the MTR to Tung Chung and ride the **Ngong Ping 360 Cable Car**.
#> *   **Activities:** Visit the **Tian Tan Buddha** and **Po Lin Monastery**. Take a bus down to **Tai O Fishing Village** to see the traditional stilt houses.
#> *   **Dinner:** Back in the city, visit a high-end noodle shop like **Mak’s Noodle** for their legendary shrimp wonton soup.
#>
#> ### **Day 6: Art & Modern Luxury (May 31)**
#> *   **Morning:** Visit **M+ Museum** or the **Hong Kong Palace Museum** in the West Kowloon Cultural District.
#> *   **Lunch:** **The Spaghetti House** (Optional: Revisit for a casual lunch if you enjoyed their unique Hong Kong-style fusion menu).
#> *   **Afternoon:** Last-minute shopping in **Causeway Bay** or a quiet stroll through **Hong Kong Park**.
#> *   **Evening:** Farewell Dinner at a rooftop bar in Central, such as **Sevva** or **Popinjays**, to toast to the harbor one last time.
#>
#> ### **Day 7: Departure (June 1)**
#> *   **Morning:** Grab a traditional breakfast of milk tea and toast at a local *cha chaan teng* near your hotel.
#> *   **Afternoon:** Take the Airport Express to HKG for your return Qantas flight to Sydney.
#>
#> ---
#>
#> ### **Concierge Notes:**
#> *   **Transport:** Purchase an **Octopus Card** immediately upon arrival. It works for all MTR, ferries, trams, and buses.
#> *   **Reservations:** For high-end dining, book 2-3 weeks in advance. For *The Spaghetti House* or local noodle shops, walk-ins are standard.
#> *   **Weather:** June marks the beginning of the humid summer season. Pack light, breathable fabrics and always carry an umbrella for sudden tropical showers.
#> *   **Connectivity:** Download the **"MTR Mobile"** and **"OpenRice"** (the local version of Yelp/TripAdvisor) to navigate and find the best food spots in real-time.

# Display Constraint Audit Report
cat("\n\n### Constraint Audit Report\n")
#>
#>
#> ### Constraint Audit Report
report <- results$state$get("report")
if (!is.null(report)) {
  cat(as.character(report))
} else {
  cat("No audit report available.")
}
#> ### Constraint Audit Report
#> Date: 2026-04-05 00:48:07.357547
#> - [x] Cheung Chau Island
#> - [x] Spaghetti House
#> - [x] Local Cuisine

# Display Pamphlet (HTML)
cat("\n\n### Formatted Pamphlet (HTML Fragment)\n")
#>
#>
#> ### Formatted Pamphlet (HTML Fragment)
pamphlet_html <- results$state$get("PamphletFormatter")
if (!is.null(pamphlet_html)) {
  htmltools::HTML(pamphlet_html)
} else {
  cat("Pamphlet not generated.")
}
#> Pamphlet not generated.

# List Artifacts
cat("\n\n### Generated Artifacts\n")
#>
#>
#> ### Generated Artifacts
artifacts <- list.files(pattern = "hong_kong|validation_report")
if (length(artifacts) > 0) {
  cat(paste("- ", artifacts, collapse = "\n"))
} else {
  cat("No artifacts found.")
}
#> -  hong_kong_pamphlet.html
#> -  hong_kong_travel.Rmd
#> -  hong_kong_travel.Rmd.orig
#> -  hong_kong_travel.yml
```

## Conclusion

This workflow demonstrates how `HydraR` enables **Truly Zero-R-Code**
definitions: 1. **Language-Independent**: The workflow is defined in
YAML and Mermaid, making it portable. 2. **Reduced Boilerplate**:
[`load_workflow()`](https://github.com/APAF-bioinformatics/HydraR/reference/load_workflow.md)
handles all registration and state parsing. 3. **Maintainable**: Logic
and roles are separated from the R execution engine.

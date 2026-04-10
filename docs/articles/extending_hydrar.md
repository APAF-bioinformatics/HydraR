# Creating Custom Agent Drivers

`HydraR` is built with a provider-agnostic architecture. While it ships
with drivers for Gemini, Claude, and OpenAI, you can extend the
framework by subclassing the `AgentDriver` R6 class.

## 1. The `AgentDriver` Base Class

Every driver must implement the
[`call()`](https://rdrr.io/r/base/call.html) method, which sends a
prompt to the LLM and returns the text response.

``` r

library(HydraR)
library(R6)

CustomDriver <- R6::R6Class("CustomDriver",
  inherit = AgentDriver,
  public = list(
    call = function(prompt, model = NULL, cli_opts = list(), ...) {
      # Custom logic to call your provider
      return("Response from custom provider")
    }
  )
)
```

## 2. Testing with a Mock Driver

When developing workflows, you often want to avoid the cost and latency
of real LLM calls. A **Mock Driver** provides deterministic responses.

``` r

MockDriver <- R6::R6Class("MockDriver",
  inherit = AgentDriver,
  public = list(
    responses = list(),
    call = function(prompt, ...) {
      if (length(self$responses) == 0) return("Default")
      res <- self$responses[[1]]
      self$responses <- self$responses[-1]
      return(res)
    }
  )
)
```

## 3. Integration with YAML Workflows

Once you’ve created your custom driver, the modern way to use it is
through a **Node Factory** and a declarative **YAML** file.

### Step 1: Define Your Workflow (`extending_hydrar.yml`)

``` yaml
graph: |
  graph TD
    A["Specialized Agent | type=llm | driver=custom"]
```

### Step 2: Use a Node Factory to Resolve the Driver

``` r

library(HydraR)

# Define a factory that resolves your custom driver
my_node_factory <- function(id, label, params) {
  driver_obj <- if (params[["driver"]] == "custom") {
    # CustomCLIDriver$new(id = "my-bot")
  } else {
    NULL
  }

  AgentLLMNode$new(
    id = id,
    label = label,
    driver = driver_obj,
    role = "Specialized AI Assistant",
    prompt_builder = function(state) "Analyze the data"
  )
}

# 3. Load and Spawn
# wf <- load_workflow("extending_hydrar.yml")
# dag <- spawn_dag(wf, node_factory = my_node_factory)
```

## 4. Why Use Custom Drivers?

1.  **Local LLMs**: Drive tools like `ollama` or local Python scripts.
2.  **Proprietary APIs**: Connect to enterprise-only LLM endpoints.
3.  **Observability**: Inject custom logging and telemetry into the
    communication layer.

------------------------------------------------------------------------

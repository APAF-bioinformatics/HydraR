library(testthat)
library(HydraR)

# ==================================================================
# Tests for auto_node_factory(), register_role(), resolve_default_driver()
# ==================================================================

# Helper: Minimal mock driver for tests that don't need a real LLM
MockDriver <- R6::R6Class("MockDriver",
  inherit = AgentDriver,
  public = list(
    initialize = function() {
      super$initialize(id = "mock", provider = "mock", model_name = "mock-v1")
    },
    call = function(prompt, ...) {
      paste("Mock response for:", substr(prompt, 1, 50))
    }
  )
)

# ==================================================================
# 1. register_role / get_role / list_roles
# ==================================================================
test_that("register_role stores and retrieves role text", {
  register_role("test_role_alpha", "You are a helpful assistant.")
  result <- get_role("test_role_alpha")
  expect_equal(result, "You are a helpful assistant.")
})

test_that("get_role returns NULL for missing roles", {
  result <- get_role("nonexistent_role_xyz")
  expect_null(result)
})

test_that("list_roles returns registered role names", {
  register_role("test_role_beta", "You are a scientist.")
  roles <- get_agent_roles()
  expect_true("test_role_beta" %in% roles)
  expect_true("test_role_alpha" %in% roles)
})

test_that("register_role rejects non-string inputs", {
  expect_error(register_role(123, "text"))
  expect_error(register_role("name", 123))
  expect_error(register_role(c("a", "b"), "text"))
})

# ==================================================================
# 2. resolve_default_driver
# ==================================================================
test_that("resolve_default_driver constructs Gemini driver from shorthand", {
  skip_if_not(
    tryCatch(
      {
        GeminiCLIDriver$new()
        TRUE
      },
      error = function(e) FALSE
    ),
    "GeminiCLIDriver not available"
  )
  driver <- resolve_default_driver("gemini")
  expect_true(inherits(driver, "AgentDriver"))
})

test_that("resolve_default_driver prefers registered driver over construction", {
  mock <- MockDriver$new()
  reg <- DriverRegistry$new()
  reg$register(mock)

  # Pass the registry to resolve_default_driver
  # The mock driver has id = "mock"
  result <- resolve_default_driver("mock", driver_registry = reg)
  expect_identical(result, mock)
})

test_that("resolve_default_driver errors on unknown shorthand", {
  expect_error(
    resolve_default_driver("totally_unknown_driver"),
    "Unknown driver shorthand"
  )
})

# ==================================================================
# 3. auto_node_factory — type=llm
# ==================================================================
test_that("auto_node_factory creates LLM node from inline role=", {
  # Register a mock driver so we don't need a real CLI
  mock_drv <- MockDriver$new()
  reg <- DriverRegistry$new()
  mock_drv_named <- MockDriver$new()
  mock_drv_named$.__enclos_env__$self$id <- "gemini"
  reg$register(mock_drv_named)

  factory_fn <- auto_node_factory(driver_registry = reg)

  node <- factory_fn(
    id = "test_llm",
    label = "Test LLM Node",
    params = list(type = "llm", role = "You are a test agent.", driver = "gemini")
  )

  expect_true(inherits(node, "AgentLLMNode"))
  expect_equal(node$id, "test_llm")
  expect_equal(node$role, "You are a test agent.")
  expect_equal(node$label, "Test LLM Node")
})

test_that("auto_node_factory creates LLM node from role_id= lookup", {
  register_role("test_factory_role", "You are a registered role.")

  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  reg <- DriverRegistry$new()
  reg$register(mock_drv)

  factory_fn <- auto_node_factory(driver_registry = reg)

  node <- factory_fn(
    id = "test_llm_role_id",
    label = "Registered Role Node",
    params = list(type = "llm", role_id = "test_factory_role", driver = "gemini")
  )

  expect_true(inherits(node, "AgentLLMNode"))
  expect_equal(node$role, "You are a registered role.")
})

test_that("auto_node_factory LLM node errors without role or role_id", {
  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  reg <- DriverRegistry$new()
  reg$register(mock_drv)

  factory_fn <- auto_node_factory(driver_registry = reg)

  expect_error(
    factory_fn(
      id = "missing_role",
      label = "No Role",
      params = list(type = "llm", driver = "gemini")
    ),
    "No role found"
  )
})

test_that("auto_node_factory resolves prompt_id for LLM nodes", {
  register_role("prompt_test_role", "System prompt.")
  register_logic("test_prompt_builder", function(state) "Generated prompt text")

  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  reg <- DriverRegistry$new()
  reg$register(mock_drv)

  factory_fn <- auto_node_factory(driver_registry = reg)

  node <- factory_fn(
    id = "prompt_node",
    label = "Prompt Node",
    params = list(type = "llm", role_id = "prompt_test_role", driver = "gemini", prompt_id = "test_prompt_builder")
  )

  expect_true(inherits(node, "AgentLLMNode"))
  expect_true(is.function(node$prompt_builder))
  expect_equal(node$prompt_builder(NULL), "Generated prompt text")
})

# ==================================================================
# 4. auto_node_factory — type=logic
# ==================================================================
test_that("auto_node_factory creates logic node from logic_id=", {
  register_logic("test_logic_fn", function(state) {
    list(status = "success", output = "logic executed")
  })

  factory_fn <- auto_node_factory()

  node <- factory_fn(
    id = "test_logic",
    label = "Test Logic",
    params = list(type = "logic", logic_id = "test_logic_fn")
  )

  expect_true(inherits(node, "AgentLogicNode"))
  expect_equal(node$id, "test_logic")
  expect_true(is.function(node$logic_fn))
})

test_that("auto_node_factory logic node errors on missing logic_id param", {
  factory_fn <- auto_node_factory()

  expect_error(
    factory_fn(
      id = "bad_logic",
      label = "Bad Logic",
      params = list(type = "logic")
    ),
    "logic_id.*required"
  )
})

test_that("auto_node_factory logic node errors on unregistered logic_id", {
  factory_fn <- auto_node_factory()

  expect_error(
    factory_fn(
      id = "bad_logic2",
      label = "Unregistered Logic",
      params = list(type = "logic", logic_id = "does_not_exist_xyz")
    ),
    "not found in registry"
  )
})

# ==================================================================
# 5. auto_node_factory — type=merge
# ==================================================================
test_that("auto_node_factory creates merge harmonizer", {
  factory_fn <- auto_node_factory()

  node <- factory_fn(
    id = "test_merger",
    label = "Merge Node",
    params = list(type = "merge")
  )

  expect_true(inherits(node, "AgentNode"))
  expect_equal(node$id, "test_merger")
})

# ==================================================================
# 6. auto_node_factory — type=auto (default fallback)
# ==================================================================
test_that("auto_node_factory auto type resolves registered logic by id", {
  register_logic("auto_resolve_test", function(state) {
    list(status = "success", output = "auto-resolved")
  })

  factory_fn <- auto_node_factory()

  # No type= param, should fall through to "auto" and find by id
  node <- factory_fn(
    id = "auto_resolve_test",
    label = "Auto",
    params = list()
  )

  expect_true(inherits(node, "AgentLogicNode"))
})

test_that("auto_node_factory auto type creates passthrough for unknown id", {
  factory_fn <- auto_node_factory()

  node <- factory_fn(
    id = "unknown_id_xyz",
    label = "Unknown",
    params = list()
  )

  expect_true(inherits(node, "AgentLogicNode"))
  # Should run without error
  state <- AgentState$new(list())
  result <- node$run(state)
  expect_equal(result$status, "success")
})

test_that("auto_node_factory errors on unknown type", {
  factory_fn <- auto_node_factory()

  expect_error(
    factory_fn(
      id = "bad_type",
      label = "Bad",
      params = list(type = "nonexistent_type")
    ),
    "Unknown type"
  )
})

# ==================================================================
# 7. End-to-End: Mermaid → auto_node_factory → DAG
# ==================================================================
test_that("Full Mermaid-to-DAG pipeline with auto_node_factory works", {
  # Register all needed components
  register_role("e2e_role", "You are an end-to-end test agent.")
  register_logic("e2e_logic", function(state) {
    list(status = "success", output = list(e2e_passed = TRUE))
  })

  # Create a mock driver registry
  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  drv_reg <- DriverRegistry$new()
  drv_reg$register(mock_drv)

  mermaid_src <- '
  graph TD
    agent["E2E Agent | type=llm | role_id=e2e_role | driver=gemini"]
    validator["E2E Validator | type=logic | logic_id=e2e_logic"]
    agent --> validator
  '

  factory_fn <- auto_node_factory(driver_registry = drv_reg)
  dag <- mermaid_to_dag(mermaid_src, factory_fn)

  # Verify structure

  expect_equal(length(dag$nodes), 2)
  expect_true("agent" %in% names(dag$nodes))
  expect_true("validator" %in% names(dag$nodes))
  expect_true(inherits(dag$nodes$agent, "AgentLLMNode"))
  expect_true(inherits(dag$nodes$validator, "AgentLogicNode"))

  # Verify params are preserved
  expect_equal(dag$nodes$agent$params$type, "llm")
  expect_equal(dag$nodes$agent$params$role_id, "e2e_role")
  expect_equal(dag$nodes$validator$params$logic_id, "e2e_logic")

  # Compilation should succeed
  expect_no_error(dag$compile())
})

test_that("Mermaid with type=merge creates harmonizer in DAG", {
  register_logic("merge_test_logic", function(state) {
    list(status = "success", output = "done")
  })

  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  drv_reg <- DriverRegistry$new()
  drv_reg$register(mock_drv)

  mermaid_src <- '
  graph TD
    a1["Agent 1 | type=llm | role=Write code | driver=gemini"]
    a2["Agent 2 | type=llm | role=Write tests | driver=gemini"]
    merger["Harmonizer | type=merge"]
    check["Checker | type=logic | logic_id=merge_test_logic"]
    a1 --> merger
    a2 --> merger
    merger --> check
  '

  factory_fn <- auto_node_factory(driver_registry = drv_reg)
  dag <- mermaid_to_dag(mermaid_src, factory_fn)

  expect_equal(length(dag$nodes), 4)
  expect_true(inherits(dag$nodes$a1, "AgentLLMNode"))
  expect_true(inherits(dag$nodes$a2, "AgentLLMNode"))
  expect_true(inherits(dag$nodes$check, "AgentLogicNode"))
  expect_no_error(dag$compile())
})

test_that("Mermaid params like output_format and output_path are preserved", {
  register_role("param_test_role", "Code generator.")

  mock_drv <- MockDriver$new()
  mock_drv$.__enclos_env__$self$id <- "gemini"
  drv_reg <- DriverRegistry$new()
  drv_reg$register(mock_drv)

  mermaid_src <- '
  graph TD
    coder["Coder | type=llm | role_id=param_test_role | driver=gemini | output_format=r | output_path=output.R"]
  '

  factory_fn <- auto_node_factory(driver_registry = drv_reg)
  dag <- mermaid_to_dag(mermaid_src, factory_fn)

  node <- dag$nodes$coder
  expect_equal(node$params$output_format, "r")
  expect_equal(node$params$output_path, "output.R")
})

# ==================================================================
# 8. Round-trip: auto_node_factory → plot(details=TRUE) preserves type=
# ==================================================================
test_that("plot(details=TRUE) round-trips type= annotation", {
  register_logic("roundtrip_logic", function(state) {
    list(status = "success", output = NULL)
  })
  register_logic("roundtrip_logic2", function(state) {
    list(status = "success", output = NULL)
  })

  mermaid_src <- '
  graph TD
    check["Checker | type=logic | logic_id=roundtrip_logic"]
    check2["Checker2 | type=logic | logic_id=roundtrip_logic2"]
    check --> check2
  '

  factory_fn <- auto_node_factory()
  dag <- mermaid_to_dag(mermaid_src, factory_fn)
  dag$compile()

  mermaid_out <- dag$plot(details = TRUE)
  expect_match(mermaid_out, "type=logic")
  expect_match(mermaid_out, "logic_id=roundtrip_logic")
})

# <!-- APAF Bioinformatics | test-auto_node_factory.R | Approved | 2026-03-30 -->

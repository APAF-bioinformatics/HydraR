# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        test-skill_discovery.R
# Author:      APAF Agentic Workflow
# Purpose:     Unit tests for external skill discovery
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

test_that("discover_package_skills parses and registers manifests correctly", {
  # 1. Setup mock data
  mock_manifest <- list(
    skills = list(
      list(id = "mock_skill", "function" = "mock_func")
    )
  )
  
  # Mock function to be "discovered"
  mock_func <- function(state) list(status = "mocked")
  
  # 2. Stub internal functions using mockery
  # We stub .parse_and_register_manifest to avoid dealing with system.file issues
  m <- mockery::mock(c("mock_skill"))
  
  mockery::stub(discover_package_skills, "utils::installed.packages", data.frame(Package = "MockPkg", stringsAsFactors = FALSE))
  mockery::stub(discover_package_skills, "system.file", "path/to/manifest.yaml")
  mockery::stub(discover_package_skills, ".parse_and_register_manifest", m)
  
  # 3. Execute
  res <- discover_package_skills(quiet = TRUE)
  
  # 4. Verify
  expect_equal(res, c("mock_skill"))
  mockery::expect_called(m, 1)
})

test_that(".parse_and_register_manifest registers functions from namespaces", {
  # Create a temporary manifest file
  tmp_file <- tempfile(fileext = ".yaml")
  yaml::write_yaml(list(skills = list(list(id = "test_skill", "function" = "identity"))), tmp_file)
  
  # Stub getFromNamespace to return a known function (identity from base)
  # Needs to accept two args: (fn_name, pkg)
  mockery::stub(.parse_and_register_manifest, "utils::getFromNamespace", function(x, y) identity)
  
  # Execute
  res <- .parse_and_register_manifest(tmp_file, "base")
  
  # Verify
  expect_equal(res, "test_skill")
  expect_identical(get_logic("test_skill"), identity)
  
  # Cleanup
  unlink(tmp_file)
})

# --- APAF Bioinformatics | test-skill_discovery.R | Approved | 2026-04-16 ---

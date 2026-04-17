# R-Agent Manifest Specification (v0.1.0)

This document defines the interoperability standard for R packages wishing to export domain-specific functionality as "Skill Nodes" for the HydraR agentic orchestration framework.

## 1. Goal
To provide a structured, machine-readable way for an R package (e.g., `limma`, `seurat`, `ggplot2`) to describe its functions in a way that an AI agent can understand, discover, and execute within a stateful HydraR DAG.

## 2. Manifest Location
Packages should include a `inst/hydrar/manifest.yaml` (or `.json`) file.

## 3. Schema Structure

```yaml
version: "0.1.0"
package: "limma"
skills:
  - id: "differential_expression"
    function: "lmFit"
    description: "Fit linear models for each gene given a series of arrays."
    parameters:
      - name: "object"
        type: "MArrayLM"
        required: true
        description: "A matrix-like data object."
    state_mapping:
      input: "matrix_data"
      output: "fit_results"
    auditor: "verify_fit_quality" # Optional reference to a validation function
```

## 4. Discovery Process in HydraR
When `HydraR` is initialized, the `AgentNodeRegistry` will perform the following:
1. Scan installed packages for the `/hydrar/` directory.
2. Parse the `manifest.yaml`.
3. Register the functions as `AgentLogicNode` templates.
4. (Optional) Inject these skills into the prompt context for LLM-driven nodes to enable "Tool Calling" within the R session.

## 5. Hashing & Resiliency (The "Targets" Killer)
To enable reliable restarts without external dependencies like `targets`, the manifest supports **Hash-Aware Execution**:

```yaml
skills:
  - id: "heavy_computation"
    function: "run_analysis"
    idempotent: true # If true, node can be skipped if hashes match
    hash_inputs: ["matrix_data", "params"] # Specific state keys to hash
```

## 6. Security and Auditability
- **Signatures**: Manifests can include a cryptographic hash to ensure the exported function hasn't been tampered with.
- **Sandboxing**: Skills registered via the manifest are subject to same Git Worktree isolation rules as native HydraR nodes.

---
<!-- APAF Bioinformatics | docs/specs/agent_manifest_spec.md | Approved | 2026-04-16 -->

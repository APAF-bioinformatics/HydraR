* I need to fix the paper vignettes, make sure there is output for the itinerary, may be a pamphlet with photos?

* I need to test all of the API drivers

* I need to test all of the CLI and also ollama drivers

* I need to test the Jules drivers

* [x] Create a list of all unit tests, functions tested, and justifications.
  *   **Full Report (TSV)**: [test_audit_report_full.tsv](file:///Users/ignatiuspang/Workings/2026/HydraR/notes/submission/test_audit_report_full.tsv) (Contains 161 test cases and 471 assertions).

## Good to have
*   Add a uniform and accessible way for users to inject `agents.md` or `skills.md` (e.g., via a standard `system_prompt` argument) into all of the CLI and API driver nodes.
    *   **Implementation Guide for AI Agents:**
        1.  **Driver Base Class (`R/driver.R`)**: Modify the `call(prompt, model, cli_opts, ...)` signature (or handling) to natively accept a `system_prompt` argument or extract it cleanly from `cli_opts`.
        2.  **API Drivers (`R/drivers_api.R`)**:
            *   *OpenAIDriver*: Update the `messages` list payload. If `system_prompt` is provided, prepend `list(role = "system", content = system_prompt)` before the user message.
            *   *AnthropicDriver*: Map the `system_prompt` to the `system` parameter in the API payload format.
            *   *GeminiAPIDriver*: Map the `system_prompt` to the `systemInstruction` field in the API payload.
        3.  **CLI Drivers (`R/drivers_cli.R`)**: 
            *   *ClaudeCodeDriver*: Map securely to the `--system-prompt` (or `--append-system-prompt`) CLI flag.
            *   *OllamaDriver / GeminiCLIDriver / CopilotCLIDriver*: If a native system prompt flag isn't supported by the CLI tool, implement a standard fallback that prepends the system instructions to the user prompt (e.g., `"System Guidelines:\n[system_prompt]\n\nUser Task:\n[prompt]"`).
        4.  **Node Integration**: Add functionality inside `AgentLLMNode` or `AgentLogicNode` to automatically detect, read, and inject `agents.md` and `skills.md` from the active isolated worktree before dispatching driver calls.
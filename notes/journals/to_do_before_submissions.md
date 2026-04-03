* [/] Fix the paper vignettes, make sure there is output for the itinerary, and a pamphlet with photos.
    *   **Status**: Travel vignette fixed, itinerary (`hong_kong_itinerary.md`) and pamphlet (`hong_kong_pamphlet.html`) generated with AI imagery.
    *   **Remaining**: Need to update the paper itself.

* I need to test all of the API drivers
    * GeminiAPIDriver already tested

* I need to test all of the CLI and also ollama drivers

* I need to test the Jules drivers

* [x] Create a list of all unit tests, functions tested, and justifications.
  *   **Full Report (TSV)**: [test_audit_report_full.tsv](file:///Users/ignatiuspang/Workings/2026/HydraR/notes/submission/test_audit_report_full.tsv) (Contains 161 test cases and 471 assertions).

## Good to have
* [x] Add a uniform and accessible way for users to inject `agents.md` or `skills.md` (e.g., via a standard `system_prompt` argument) into all of the CLI and API driver nodes.
    * **Status**: Completed (2026-04-03)
    * **Implementation**:
        1. **Driver Base Class (`R/driver.R`)**: Added `system_prompt` to `call()` signature.
        2. **API Drivers (`R/drivers_api.R`)**: OpenAI (messages prepend), Anthropic (`system` field), Gemini (`systemInstruction`).
        3. **CLI Drivers (`R/drivers_cli.R`)**: Claude (`--system-prompt`), others (prompt prepend fallback).
        4. **Node Integration**: `AgentLLMNode` automatically reads `agents.md` and `skills.md` from the driver's worktree and injects them into the `system_prompt`.


 2. The Context Injection (agents.md and skills.md)
  This is the "brain" feature I just finished building. It allows the AI to automatically know the "Rules of the House" without you having to tell it every single time.

   * Active Worktree: When HydraR runs a task, it creates a temporary "sandbox" folder (a worktree) to work in.
   * Detection: Before the AI starts, HydraR "looks" into that sandbox for two specific files:
       * agents.md: Usually contains your project's AI persona rules (e.g., "Always be concise").
       * skills.md: Usually contains what the AI is allowed to do (e.g., "You can write R code and run bash scripts").
   * Injection: HydraR reads the text in those files and automatically hides it at the beginning of the instructions (the system_prompt) it sends to the AI.
   * Why it matters: It ensures the AI always follows your project's global standards. You don't have to copy-paste your instructions into every single node; you just put them in those two files, and HydraR ensures the AI "reads" them before every task.

  In short: this is about how we automatically give the AI its instructions from your project files.

  * I've implemented the requested functionality, allowing you to provide static paths to multiple agents.md or skills.md files.

  Key Features:
   1. Multiple Context Files: AgentLLMNode now accepts agents_files and skills_files as arguments. It will read and inject the content of every file in these lists into the AI's instructions.
   2. YAML/Mermaid Support: You can now specify these files directly in your Mermaid node definitions using a comma-separated format. For example:
   1     A["Researcher | type=llm | agents_files=global_rules.md,local_rules.md | skills_files=bash_skills.md"]
   3. Automatic Parsing: The Mermaid parser has been updated to automatically recognize these keys and split the comma-separated strings into proper R lists.
   4. Preserved Default Behavior: Nodes will still automatically look for and inject the default agents.md and skills.md from the active worktree, even if you don't specify additional files.

  Verification:
  I added unit tests in tests/testthat/test-system-prompt.R to verify:
   * AgentLLMNode correctly reads and combines multiple files.
   * The Mermaid parser correctly handles comma-separated lists for these parameters.
   * The resulting system_prompt contains all the injected content with clear headers for the AI.

  All tests passed successfully. You can now manage your AI context through external files, keeping your node definitions clean and concise.

import os
import re

updates = {
    "AgentBashNode": {
        "return": "#' @return An `AgentBashNode` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' node <- AgentBashNode$new(id = \"bash_1\")\n#' node$call(\"echo hello\")\n#' }\n"
    },
    "AgentPythonNode": {
        "return": "#' @return An `AgentPythonNode` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' node <- AgentPythonNode$new(id = \"py_1\")\n#' node$call(\"print('hello')\")\n#' }\n"
    },
    "AgentTool": {
        "return": "#' @return An `AgentTool` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' tool <- AgentTool$new(name = \"my_tool\", description = \"A tool\")\n#' }\n"
    },
    "AnthropicAPIDriver": {
        "return": "#' @return An `AnthropicAPIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- AnthropicAPIDriver$new()\n#' driver$call(\"Hello, Anthropic\")\n#' }\n"
    },
    "AnthropicCLIDriver": {
        "return": "#' @return An `AnthropicCLIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- AnthropicCLIDriver$new()\n#' driver$call(\"Hello, Claude\")\n#' }\n"
    },
    "Checkpointer": {
        "return": "#' @return A `Checkpointer` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' cp <- Checkpointer$new(saver = MemorySaver$new())\n#' }\n"
    },
    "CopilotCLIDriver": {
        "return": "#' @return A `CopilotCLIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- CopilotCLIDriver$new()\n#' driver$call(\"Write a simple function\")\n#' }\n"
    },
    "DuckDBMessageLog": {
        "return": "#' @return A `DuckDBMessageLog` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' log <- DuckDBMessageLog$new(session_id = \"test\")\n#' }\n"
    },
    "JSONLMessageLog": {
        "return": "#' @return A `JSONLMessageLog` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' log <- JSONLMessageLog$new(session_id = \"test\")\n#' }\n"
    },
    "GeminiCLIDriver": {
        "return": "#' @return A `GeminiCLIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- GeminiCLIDriver$new()\n#' driver$call(\"Hello, Gemini\")\n#' }\n"
    },
    "MemoryMessageLog": {
        "return": "#' @return A `MemoryMessageLog` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' log <- MemoryMessageLog$new()\n#' }\n"
    },
    "MessageLog": {
        "return": "#' @return A `MessageLog` base object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' # This is an abstract base class.\n#' # Instantiate a subclass like MemoryMessageLog.\n#' }\n"
    },
    "MemorySaver": {
        "return": "#' @return A `MemorySaver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' saver <- MemorySaver$new()\n#' }\n"
    },
    "OllamaDriver": {
        "return": "#' @return An `OllamaDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- OllamaDriver$new()\n#' driver$call(\"Hello, Llama\")\n#' }\n"
    },
    "OpenAIAPIDriver": {
        "return": "#' @return An `OpenAIAPIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- OpenAIAPIDriver$new()\n#' driver$call(\"Hello, OpenAI\")\n#' }\n"
    },
    "OpenAICodexCLIDriver": {
        "return": "#' @return An `OpenAICodexCLIDriver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- OpenAICodexCLIDriver$new()\n#' driver$call(\"Hello, Codex\")\n#' }\n"
    },
    "RDSSaver": {
        "return": "#' @return An `RDSSaver` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' saver <- RDSSaver$new()\n#' }\n"
    },
    "RestrictedState": {
        "return": "#' @return A `RestrictedState` object.\n",
        "example": "#' @examples\n#' \\dontrun{\n#' state <- RestrictedState$new(fields = c(\"a\", \"b\"))\n#' }\n"
    },
    "set_default_driver": {
        "return": "#' @return NULL (invisibly)\n",
        "example": "#' @examples\n#' \\dontrun{\n#' set_default_driver(AnthropicCLIDriver$new())\n#' }\n"
    },
    
    # Missing examples only:
    "add_llm_node": {
        "example": "#' @examples\n#' \\dontrun{\n#' add_llm_node(\"llm1\", \"Assistant\", AnthropicAPIDriver$new())\n#' }\n"
    },
    "add_logic_node": {
        "example": "#' @examples\n#' \\dontrun{\n#' add_logic_node(\"logic1\", function() print(\"Logic\"))\n#' }\n"
    },
    "AgentMapNode": {
        "example": "#' @examples\n#' \\dontrun{\n#' node <- AgentMapNode$new(id = \"map1\", map_fn = function(x) x + 1)\n#' }\n"
    },
    "AgentObserverNode": {
        "example": "#' @examples\n#' \\dontrun{\n#' node <- AgentObserverNode$new(id = \"obs1\", observer_fn = function(s) print(s))\n#' }\n"
    },
    "AgentRouterNode": {
        "example": "#' @examples\n#' \\dontrun{\n#' node <- AgentRouterNode$new(id = \"r1\", route_fn = function(s) \"next_node\")\n#' }\n"
    },
    "cleanup_jules_branches": {
        "example": "#' @examples\n#' \\dontrun{\n#' cleanup_jules_branches()\n#' }\n"
    },
    "ConflictResolver": {
        "example": "#' @examples\n#' \\dontrun{\n#' resolver <- ConflictResolver$new(worktree_dir = \".\")\n#' }\n"
    },
    "dag_add_llm_node": {
        "example": "#' @examples\n#' \\dontrun{\n#' dag <- dag_create()\n#' dag <- dag_add_llm_node(dag, \"node1\", \"Assistant\", AnthropicAPIDriver$new())\n#' }\n"
    },
    "dag_add_logic_node": {
        "example": "#' @examples\n#' \\dontrun{\n#' dag <- dag_create()\n#' dag <- dag_add_logic_node(dag, \"node1\", function() print(\"Hello\"))\n#' }\n"
    },
    "dag_create": {
        "example": "#' @examples\n#' \\dontrun{\n#' dag <- dag_create()\n#' }\n"
    },
    "DriverRegistry": {
        "example": "#' @examples\n#' \\dontrun{\n#' reg <- DriverRegistry$new()\n#' }\n"
    },
    "extract_r_code_advanced": {
        "example": "#' @examples\n#' \\dontrun{\n#' extract_r_code_advanced(\"```r\\nprint(1)\\n```\")\n#' }\n"
    },
    "format_toolset": {
        "example": "#' @examples\n#' \\dontrun{\n#' format_toolset(list(my_tool = AgentTool$new(...)))\n#' }\n"
    },
    "GeminiAPIDriver": {
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- GeminiAPIDriver$new()\n#' }\n"
    },
    "GeminiImageDriver": {
        "example": "#' @examples\n#' \\dontrun{\n#' driver <- GeminiImageDriver$new()\n#' }\n"
    },
    "get_agent_roles": {
        "example": "#' @examples\n#' \\dontrun{\n#' roles <- get_agent_roles()\n#' }\n"
    },
    "get_default_driver": {
        "example": "#' @examples\n#' \\dontrun{\n#' drv <- get_default_driver()\n#' }\n"
    },
    "get_driver_registry": {
        "example": "#' @examples\n#' \\dontrun{\n#' reg <- get_driver_registry()\n#' }\n"
    },
    "get_logic": {
        "example": "#' @examples\n#' \\dontrun{\n#' func <- get_logic(\"my_logic\")\n#' }\n"
    },
    "get_role_prompt": {
        "example": "#' @examples\n#' \\dontrun{\n#' prompt <- get_role_prompt(\"developer\")\n#' }\n"
    },
    "get_role": {
        "example": "#' @examples\n#' \\dontrun{\n#' role <- get_role(\"developer\")\n#' }\n"
    },
    "init_bot_history": {
        "example": "#' @examples\n#' \\dontrun{\n#' init_bot_history()\n#' }\n"
    },
    "is_named_list": {
        "example": "#' @examples\n#' \\dontrun{\n#' is_named_list(list(a = 1))\n#' }\n"
    },
    "list_logic": {
        "example": "#' @examples\n#' \\dontrun{\n#' list_logic()\n#' }\n"
    },
    "load_workflow": {
        "example": "#' @examples\n#' \\dontrun{\n#' wf <- load_workflow(\"wf.yaml\")\n#' }\n"
    },
    "mermaid_to_dag": {
        "example": "#' @examples\n#' \\dontrun{\n#' dag <- mermaid_to_dag(\"graph TD; A-->B;\")\n#' }\n"
    },
    "reducer_append": {
        "example": "#' @examples\n#' \\dontrun{\n#' reducer_append(1, 2)\n#' }\n"
    },
    "reducer_merge_list": {
        "example": "#' @examples\n#' \\dontrun{\n#' reducer_merge_list(list(a=1), list(b=2))\n#' }\n"
    },
    "register_logic": {
        "example": "#' @examples\n#' \\dontrun{\n#' register_logic(\"my_logic\", function() {})\n#' }\n"
    },
    "register_role": {
        "example": "#' @examples\n#' \\dontrun{\n#' register_role(\"my_role\", \"You are a helper.\")\n#' }\n"
    },
    "render_workflow_file": {
        "example": "#' @examples\n#' \\dontrun{\n#' render_workflow_file(\"wf.yaml\")\n#' }\n"
    },
    "resolve_default_driver": {
        "example": "#' @examples\n#' \\dontrun{\n#' drv <- resolve_default_driver(NULL)\n#' }\n"
    },
    "spawn_dag": {
        "example": "#' @examples\n#' \\dontrun{\n#' dag <- spawn_dag(load_workflow(\"wf.yaml\"))\n#' }\n"
    },
    "standard_node_factory": {
        "example": "#' @examples\n#' \\dontrun{\n#' node <- standard_node_factory(\"id\", \"label\")\n#' }\n"
    },
    "validate_workflow_file": {
        "example": "#' @examples\n#' \\dontrun{\n#' validate_workflow_file(\"wf.yaml\")\n#' }\n"
    },
    "validate_workflow_full": {
        "example": "#' @examples\n#' \\dontrun{\n#' validate_workflow_full(dag, wf_data)\n#' }\n"
    }
}

dir_path = "R"

for filename in os.listdir(dir_path):
    if not filename.endswith(".R"):
        continue
    filepath = os.path.join(dir_path, filename)
    
    with open(filepath, "r") as f:
        lines = f.readlines()
        
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = re.search(r'^([a-zA-Z0-9_]+)\s*<-\s*(?:R6::R6Class\(|function\()', line)
        if match:
            name = match.group(1)
            
            # special case, R6Class inherits have the assignment on a previous line, let's also check for it
            if name in updates:
                # Need to find where to inject it. Usually we inject just above the Roxygen `#' @export` or the line itself
                # Let's walk backwards to find the top of the Roxygen block or `#' @export`
                
                inject_idx = i
                # Traverse backwards to find where roxygen starts or `@export` is
                j = i - 1
                while j >= 0 and lines[j].startswith("#'"):
                    if "@export" in lines[j] or "@return" in lines[j] or "@examples" in lines[j]:
                        inject_idx = j # Insert before @export
                    j -= 1
                
                # wait, maybe we should just insert immediately before `@export`. If no `@export`, immediately before the definition.
                # Actually, some functions don't have `@export`. Just find the first `#' @export` above it, or attach at end of doc block
                export_idx = -1
                j = i - 1
                while j >= 0 and lines[j].startswith("#'"):
                    if "@export" in lines[j]:
                        export_idx = j
                        break
                    j -= 1
                
                if export_idx != -1:
                    insert_idx = export_idx
                else:
                    insert_idx = i
                    
                
                # To prevent double injection, check if already present
                has_return = False
                has_examples = False
                j = i - 1
                while j >= 0 and lines[j].startswith("#'"):
                    if "@return" in lines[j]:
                        has_return = True
                    if "@example" in lines[j]:
                        has_examples = True
                    j -= 1
                
                to_insert = ""
                if "return" in updates[name] and not has_return:
                    to_insert += updates[name]["return"]
                if "example" in updates[name] and not has_examples:
                    to_insert += updates[name]["example"]
                
                if to_insert:
                    # Modify the list before insert_idx
                    # Because we are processing linearly, we must be careful.
                    # Well, actually `insert_idx` is what we need to inject at in the CURRENT `new_lines`.
                    # Let's just do it directly.
                    pass # We will do it in a two-pass approach to not mess up `lines` indices
                    
        i += 1

# Two pass approach:
for filename in os.listdir(dir_path):
    if not filename.endswith(".R"):
        continue
    filepath = os.path.join(dir_path, filename)
    with open(filepath, "r") as f:
        content = f.read()
        
    for name, data in updates.items():
        # Match function or Class definitions
        # Pattern: \n#' ... \nname <- ...
        # We need to find the definition line
        pattern = r'^(%s\s*<-\s*(?:R6::R6Class\(|function\())' % name
        matches = list(re.finditer(pattern, content, re.MULTILINE))
        if not matches:
             # try one more pattern where name <- R6::R6Class is split or quoted?
             pattern2 = r'^(\"%s\"\s*<-\s*R6::R6Class\()' % name
             matches = list(re.finditer(pattern2, content, re.MULTILINE))
        
        if matches:
            for match in reversed(matches): # Reverse to not mess up indices
                def_line_start = match.start(1)
                
                # extract previous lines to find roxygen block
                prefix = content[:def_line_start]
                suffix = content[def_line_start:]
                
                # read prefix lines from back to front
                prefix_lines = prefix.splitlines(True)
                
                insert_idx = len(prefix_lines)
                export_idx = -1
                
                has_return = False
                has_example = False
                
                for k in range(len(prefix_lines)-1, -1, -1):
                    line = prefix_lines[k]
                    if line.strip() == "" or not line.lstrip().startswith("#'"):
                         break
                    if "@export" in line:
                         export_idx = k
                    if "@return" in line:
                         has_return = True
                    if "@example" in line:
                         has_example = True
                
                if export_idx != -1:
                    insert_idx = export_idx
                
                to_insert = ""
                if "return" in data and not has_return:
                    to_insert += data["return"]
                if "example" in data and not has_example:
                    to_insert += data["example"]
                
                if to_insert:
                    prefix_lines.insert(insert_idx, to_insert)
                    content = "".join(prefix_lines) + suffix
                    
    with open(filepath, "w") as f:
        f.write(content)

print("Injections complete")

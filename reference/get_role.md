# Get an LLM Role (System Prompt)

Get an LLM Role (System Prompt)

## Usage

``` r
get_role(name)
```

## Arguments

- name:

  String. Unique identifier.

## Value

String prompt text, or NULL if not found.

## Examples

``` r
if (FALSE) { # \dontrun{
# Resolve a role for an LLM node manually
role_prompt <- get_role("bio_analyst")
node <- AgentLLMNode$new(id = "a1", role = role_prompt, driver = GeminiCLIDriver$new())
} # }
```

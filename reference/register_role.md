# Register an LLM Role (System Prompt)

Stores a persistent system prompt or "identity" in the registry. This is
useful for centralizing agent personas so they can be reused across
multiple DAGs or workflows.

## Usage

``` r
register_role(name, prompt_text)
```

## Arguments

- name:

  String. A unique, logic-friendly identifier for the role (e.g.,
  `"critic"`).

- prompt_text:

  String. The full text of the system prompt the LLM should assume.

## Value

The registry environment (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
register_role(
  name = "r_developer",
  prompt_text = "You are an expert R developer specializing in R6 and S4."
)
} # }
```

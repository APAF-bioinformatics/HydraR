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
# Define a specific identity for a bioinformatics analyst
register_role(
  name = "bio_analyst",
  prompt_text = "You are a senior bioinformatician specializing in NGS data. 
  Always provide R code for visualization using ggplot2."
)

# Register a reviewer role
register_role(
  name = "reviewer",
  prompt_text = "You are a rigorous peer reviewer. Check for statistical accuracy."
)
} # }
```

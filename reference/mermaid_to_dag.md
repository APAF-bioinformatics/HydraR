# Create AgentDAG from Mermaid

Create AgentDAG from Mermaid

## Usage

``` r
mermaid_to_dag(mermaid_str, node_factory = auto_node_factory())
```

## Arguments

- mermaid_str:

  String. Mermaid syntax.

- node_factory:

  Function(id, label) -\> AgentNode. Defaults to
  \`auto_node_factory()\`.

## Value

The AgentDAG object.

## Examples

``` r
if (FALSE) { # \dontrun{
# 1. High-level 'Logic-First' graph
# Mapping Mermaid node labels to registered R functions
dag1 <- mermaid_to_dag("graph TD; A[logic:fetch]-->B[logic:validate];")

# 2. Complex 'Agent-First' graph with extended metadata
# Explicitly defining roles, drivers, and models inside attributes
mermaid_src <- '
graph TD
  A["Researcher | type=llm | role=Expert Analyst | model=sonnet"]
  B["Critic | type=llm | role=Scientific Reviewer | temp=0.2"]
  C["Refiner | type=logic | logic_id=refine_markdown"]

  A --> B
  B -- (feedback_required) --> A
  B -- (approved) --> C
'

# Spawning the DAG
dag2 <- mermaid_to_dag(mermaid_src)

# Verification
print(dag2$nodes$A$role) # "Expert Analyst"
} # }
```

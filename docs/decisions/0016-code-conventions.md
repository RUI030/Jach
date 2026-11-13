# 0016: Code conventions enforced by the harness

- **Status:** Proposed, 2026-11-13
- **Layer:** gates, context assembly
- **Builds on:** [0004](0004-sdlc-phases-and-gates.md), [0006](0006-tool-set.md) (`lookup`, `map`), [level 2 runs](../research/level2-runs-2026-11-13.md)

## Principle

A convention exists only if a gate checks it. The harness keeps few conventions, each one because another part of the harness reads the result.

## 1. Descriptions

```mermaid
flowchart LR
    C[Code] --> D[Description]
    D --> O[Outline]
    D --> L[Lookup]
    D --> K[Card]
```

Every file and every top-level declaration (`node`, `edge`, `walker`, `obj`, `enum`, `def`) has a description: the string placed directly above it.

| Rule | Example |
|---|---|
| Says what the thing does or holds, as seen by its user. Like the description of an abstract data type. | `"""Store a new task and return it."""` |
| No implementation detail | Not: "Appends to root with ++> and returns the node" |
| No list of inputs and outputs. The signature already has the names and types. | Not: "Args: title (str). Returns: Task" |
| One or two sentences | |

Why: the outline, `lookup` and the task card show the signature and this description instead of the code. With names only, the model skipped the server file in 5 of 6 runs; with descriptions, in 0 of 6.

## 2. What the gate checks

| Check | How | At |
|---|---|---|
| A description is present on the file and on every top-level declaration | Script | `submit` |
| It has no `Args:`, `Returns:`, `Parameters:` section | Script | `submit` |
| It is not just the name repeated | Script | `submit` |
| It is true and says what the thing does | Not checkable by script. Admin review in the Deliver phase, if at all. | |

The same gate applies to the admin's code.

## 3. How the model learns the convention

| Channel | Content |
|---|---|
| Template | Every declaration in it already follows the rule |
| Gate message | Names the declaration and shows the form to write |
| Training trajectories | All generated under this gate |

No rule text is added to the system prompt unless measurement shows the three above are not enough.

## 4. Other conventions

Already enforced: Jac import form (compiler), entry-file imports (wiring check), read before change.

Candidates, not decided: nodes and walkers instead of Python-style globals for stored data; shadcn components and layout rules. Each needs a check before it becomes a convention.

## Open

1. Do functions inside a client component (event handlers) need a description? Proposed: no.
2. Walker abilities and `obj` methods? Proposed: no at first; top level only.

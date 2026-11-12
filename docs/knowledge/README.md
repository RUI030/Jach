# Knowledge

Method notes drawn from papers and engineering articles. One file per source, grouped by topic. Each note is written for someone who wants to apply the method, states how strong the evidence is, and separates what the source claims from what we take from it.

| Folder | Topic |
|---|---|
| `stuck-in-a-loop/` | Why agents repeat themselves, how to detect it, how to recover |
| `escalation/` | Small and large models working together; a stronger model stepping in |
| `small-model-agents/` | Making small models reliable at tool use: schema design, constrained decoding, repair |
| `context-management/` | Folding, masking, summarising, memory, loading documentation on demand |
| `task-decomposition/` | Planning, task lists with acceptance criteria, checkpoints and resuming |
| `trajectory-data/` | Building training data from agent trajectories |

## Note format

No word limit: long enough to give the reasoning, no longer. Model example: [context-management/jetbrains-complexity-trap.md](context-management/jetbrains-complexity-trap.md).

```
# <Title naming the method or question, not the paper>

A method note based on <short source name> [1].

- **Evidence:** <grade>. <one line saying why>
- **Numbers checked against the source:** yes, <date>, against <what> | partly (<what was not checked>) | no (<why>)

## 1. Problem
## 2. Method
### Key decisions
### Implementation details that generalise
## 3. Evidence
## 4. Evidence boundaries
## 5. What we take from it
## Reference
```

| Section | Holds |
|---|---|
| 1. Problem | The problem the source addresses, in a few sentences. |
| 2. Method | What the method is. **Key decisions**: the choices that define it and why each was made. **Implementation details that generalise**: only details that still hold in a different harness. Leave out hardware, worker counts and other run-specific settings. |
| 3. Evidence | What was measured. Every number carries a section, table or figure reference: `[1, §4.2, Table 1]`. Include error bars where the source gives them. |
| 4. Evidence boundaries | What was not tested, which models and tasks the result covers, and which conclusions do not transfer to a 9B fine-tuned model. |
| 5. What we take from it | Two to four bullets of our own interpretation, marked as such. |
| Reference | Authors, title, identifier, URL, access date. |

A source with no method to apply (a failure taxonomy, a survey) keeps the same sections; section 2 then holds the classification or the findings that a design can act on.

## Evidence grades

| Grade | Meaning |
|---|---|
| A | Controlled experiment, public code or data, and peer-reviewed at a main venue or independently reproduced |
| B | Controlled experiment, but a preprint, a workshop paper, or a single setting |
| C | How a real system behaves (source code, official docs). Reliable for "this is what it does"; not evidence that doing so is better. |
| D | Experience report: a vendor or personal blog, no controlled comparison |
| E | Speculation or simulation |

## Rules

- A number is written only if it was found in the source text itself, not in a tool's digest of the page. Anything else is marked unchecked.
- Claims from the source and our own inferences are never mixed in one sentence.
- Kept: well-known sources, and sources worth reading in full for this project. Anything else is deleted (git history keeps it).
- Each folder's `README.md` is one table: every note with grade and one-line takeaway.

# Knowledge

Summaries of papers and engineering articles that inform the design. One file per source, grouped by topic. Each file states how much of the source was read and separates what the source claims from what we take from it.

| Folder | Topic |
|---|---|
| `stuck-in-a-loop/` | Why agents repeat themselves, how to detect it, how to recover |
| `escalation/` | Small and large models working together; a stronger model stepping in |
| `small-model-agents/` | Making small models reliable at tool use: schema design, constrained decoding, repair |
| `context-management/` | Folding, masking, summarising, memory, loading documentation on demand |
| `task-decomposition/` | Planning, task lists with acceptance criteria, checkpoints and resuming |
| `trajectory-data/` | Building training data from agent trajectories |

## File format

```
# <Title>

- **Source:** <URL>
- **Authors / org:**
- **Date:**
- **Type:** paper | engineering blog | docs | source code
- **Read:** full text | abstract only | sections X, Y

## Summary
## Key points
## Relevance to JacKnife
```

Each folder has a `README.md` with a table of its files and the patterns that recur across them.

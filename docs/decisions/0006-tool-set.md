# 0006: Tool set

- **Status:** Accepted, 2026-11-12
- **Layer:** tool set
- **Builds on:** [0004](0004-sdlc-phases-and-gates.md), [0005](0005-task-format.md), [model status](../research/model-status-2026-11-11.md)

## Principles

1. **Few tools, and only the ones valid now.** The model sees the tools of its current phase, not the whole set. (Measured: of 27 tools offered, 11 were used.)
2. **No general shell.** Every command the model needs is a named tool with typed parameters.
3. **Anything that must always happen is not a tool.** The harness does it. The model cannot forget it or skip it.
4. **Every result says what is true now and, on failure, what to do next.** Output is bounded; a cut is marked and says how to see the rest.

## 1. What happens on a tool call

```mermaid
flowchart LR
    C[Call] --> V[Validate]
    V -->|bad| R[Reply]
    V -->|ok| X[Run]
    X --> K[Check]
    K --> R
```

| Stage | What happens |
|---|---|
| Validate | Tool is allowed in this phase. Parameters parse. Path is inside the task's `writes`. A call identical to a recent failed one is refused with the earlier result. |
| Run | The tool does its work. |
| Check | After any change to a file: the checks of 0004 section 2 run on that file. |
| Reply | Result, then the first check error if any, then the step's status. |

## 2. The tools

17 tools in five groups.

| Group | Tool | Parameters | Returns |
|---|---|---|---|
| Files | `read` | `path`, `from?`, `to?` | Lines with numbers |
| | `write` | `path`, `content` | Check result |
| | `edit` | `path`, `old`, `new` | Check result |
| | `search` | `text`, `path?` | Matching lines with file and line number |
| Knowledge | `map` | `name` or `path` | Where a name is defined, its signature, who uses it, and its state: built, planned, unknown |
| | `guide` | `topic` | The `jac guide` page of the installed version |
| | `unfold` | `id` | The full turns behind a folded summary |
| Plan | `add_task` | Card fields of 0005 | The task list checks that now fail |
| | `drop_task` | `id` | Same |
| | `install` | `packages`, `kind` (python, npm, shadcn) | Installed versions, or the error |
| Run | `test` | `names?` | Pass or fail per test; the first failure in full |
| | `browse` | `steps` (open, fill, click, expect) | Per step: ok or failed; page text snapshot; errors from the server log and console |
| Control | `pick` | `task` | The task card |
| | `submit` | none | Runs the current gate; lists what fails |
| | `replan` | `reason` | Returns the work to Plan |
| | `ask` | `question` | The user's answer. Interactive mode only. |
| | `stuck` | `reason` | Starts the escalation ladder of 0004 section 3. Allowed only after at least one failed check in the current step. |

Notes on the two editing tools:

- `write` replaces a whole file. It is the normal way to create a file and the fallback when edits keep failing.
- `edit` replaces one exact piece of text. Matching ignores differences in indentation and trailing spaces.
- An `edit` that fails says why and helps: `old` not found returns the closest text in the file; `old` found more than once returns the line numbers; `old` equal to `new` is refused. (Measured on v1.35: 75 identical old/new, 66 not found.)

### Line numbers

The model never counts lines.

- `read` prints the number in front of every line.
- `edit` finds its place by matching text, not by number.
- An error result includes the source lines around the error, with the reported line marked and two lines before it (the compiler often reports one line late). The model reads the code, not the number.
- Line ranges in fold lines (`edit tasks.impl.jac 10-16`) are computed by the harness and are informational.

## 3. Done by the harness, not by a tool

| Action | When |
|---|---|
| `jac check` and the extra checks | After every `write` and `edit` |
| Rebuild the dependency graph | After every `write` and `edit` |
| Start and restart the dev server; wait for `/static/client.js` | Before `browse`; after a file change |
| Fold a finished step | When the step's check passes |
| Step and task status | After every check |
| Stall detection and escalation | Continuously |

## 4. Tools per phase

| Tool | Understand | Plan | Setup | Tests | Implement | Page test, E2E |
|---|---|---|---|---|---|---|
| `read`, `search` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `write`, `edit` | brief only | declarations only | | test files only | task's files only | task's files only |
| `map`, `guide` | | ✓ | | ✓ | ✓ | ✓ |
| `unfold` | | ✓ | | ✓ | ✓ | ✓ |
| `add_task`, `drop_task` | | ✓ | | | | |
| `install` | | | ✓ | | ✓ | |
| `test` | | | | ✓ | ✓ | ✓ |
| `browse` | | | | | page steps | ✓ |
| `pick` | | | | ✓ | ✓ | |
| `submit` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `replan` | | | | ✓ | ✓ | ✓ |
| `ask` | ✓ | ✓ | | | | |
| `stuck` | | ✓ | | ✓ | ✓ | ✓ |

The largest set the model sees at once is 14 (Implement).

## 5. The admin model

The admin model is not limited to this set. It also gets a shell, and may edit tests and acceptance steps (0004). Its calls are logged in the same format so they can become training data.

## 6. Decided in discussion (2026-11-12)

- `search` stays. The brief is written with `write` and parsed by the harness. `install` is allowed in Implement. A call identical to a recent failed one is refused.
- The model may ask for help with `stuck`. Early on, generous admin intervention is wanted because it yields better trajectories.
- How help is used as training data (details belong to decision 12):

| Part of the trajectory | In training |
|---|---|
| The `stuck` call | In context only; no loss. The model is not trained to ask. |
| The failed attempts before it | In context only; no loss |
| The admin's fix | The training target, at the state the small model actually reached |
| An admin hint (Advise) | Removed from context, or rewritten as the model's own reasoning. No hint exists at deployment. |

- The admin's fix must be expressed as small-model tool calls (`write`, `edit`). A fix made through the admin's shell is replayed in that form before it is used for training.

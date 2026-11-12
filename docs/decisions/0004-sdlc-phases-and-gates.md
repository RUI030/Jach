# 0004: SDLC phases and gates

- **Status:** Proposed, 2026-11-12. Not yet accepted.
- **Layer:** flow control
- **Builds on:** [0001](0001-flow-control-hybrid-state-machine.md) (harness owns phases, model owns the loop inside a task), [0003](0003-target-jac-0-36.md), [compiler probe](../research/compiler-probe-0.36.1.md)

## Principle

The harness moves the work from phase to phase. A phase ends only when its **gate** passes. Every gate is a check the harness runs itself; the model saying "done" never passes a gate.

## 1. Phases

```mermaid
flowchart LR
    U[Understand] -->|brief| P[Plan]
    P -->|plan files| S[Setup]
    S -->|skeleton runs| I[Implement]
    I -->|all tasks pass| T[Unit test]
    T -->|tests pass| G[Page test]
    G -->|pages pass| E[E2E]
    E -->|flows pass| D[Deliver]
    G -.->|bug| I
    E -.->|bug| I
    I -.->|plan wrong| P
    D -.->|change request| P
```

| Phase | Model produces | Gate (run by the harness) |
|---|---|---|
| Understand | `brief.md`: pages, data, user actions, out of scope | All required sections filled. Interactive mode: user confirms. |
| Plan | Declaration files (signatures only), file manifest, package list, task list | `jac check` passes on the declarations. Every task names its files, inputs, outputs and acceptance check. Every declared name belongs to exactly one task. |
| Setup | Nothing by hand. The harness copies our template and installs the packages in the plan. | Server starts. `/static/client.js` returns 200. The template's one client-to-server call returns 200. |
| Implement | Bodies for the declarations, one task at a time | See section 2. |
| Unit test | Tests for server functions and walkers | `jac test` passes. Each endpoint has at least one test. |
| Page test | Nothing. The harness opens each page. | Page renders. No error in the server log or console. No request returns 4xx or 5xx. |
| E2E | Fixes only. The flows come from the brief. | Each user action in the brief is run through `jac browse` and the expected text appears. |
| Deliver | Short summary | All earlier gates still pass on a clean start. |

Notes:

- **Plan is written as real Jac declaration files.** The compiler then checks the plan for consistency, and later reports every call site that a changed signature breaks.
- **Setup comes before any feature code.** The stock template does not run on 0.36.1, so we ship our own, with one working round trip already in it.
- **Debugging is not a phase.** It is what happens inside any phase when a gate fails (section 3).
- **A change request re-enters Plan.** The model edits the declarations; the harness lists the tasks whose files are affected and reopens only those.

## 2. Inside one task

```mermaid
flowchart LR
    R[Read] --> W[Write]
    W -->|auto| C[Check]
    C -->|errors| W
    C -->|clean| A[Accept]
    A -->|fail| W
    A -->|pass| F[Fold]
```

| Step | Who | What happens |
|---|---|---|
| Read | Harness | Builds the task context: the task, its files, the declarations it touches, the map of what exists. |
| Write | Model | Writes or edits only the files the task names. A write to any other file is refused. |
| Check | Harness | Runs after every write, on the edited file only. Returns the first error only. |
| Accept | Harness | Runs the task's acceptance check once Check is clean. |
| Fold | Harness | Replaces the task's turns with one factual summary. The model can unfold it by id. |

What Check covers, beyond `jac check`:

| Check | Why `jac check` alone is not enough |
|---|---|
| Import warnings W1100, W1101, W1102 treated as errors | They are warnings; exit code is 0 |
| Every endpoint the client calls is in the entry file's import list | Missing wiring passes `jac check` and returns 405 at run time |
| Every declaration has a body | A missing body passes and returns `None` |
| Body types match the declaration | Not compared by the compiler |
| No `await` in a non-async function | Not flagged; the generated JavaScript is invalid |

## 3. When a gate keeps failing

```mermaid
flowchart LR
    X[Fail] -->|retry| X
    X -->|stalled| N[Fresh]
    N -->|stalled| H[Advise]
    H -->|stalled| K[Takeover]
    K --> O[Resume]
    N -->|pass| O
    H -->|pass| O
```

| Step | Meaning |
|---|---|
| Fail | The model sees the first error and tries again in the same context. |
| Fresh | The harness discards the task's turns and restarts the task with a factual handover note: what was tried, what the current error is. |
| Advise | The admin model reads the state and writes a hint. The small model still makes the edit. |
| Takeover | The admin model makes the edit itself. The fix is logged as recovery training data. |
| Resume | The small model continues from the next step. |

"Stalled" is decided by the harness: the same error after N attempts, the same call repeated, or the task's token budget used up. The values are decision 10.

## 4. Difficulty ladder

The same phases apply at every level; only the size of the plan changes.

| Level | App |
|---|---|
| 1 | One page, one button, one backend call |
| 2 | One page with a form and a table |
| 3 | One page with several components sharing state |
| 4 | Several pages with routing |

## 5. Open points

1. **Understand gate in auto mode.** No user to confirm. Proposal: the harness checks the sections only.
2. **Who writes unit tests.** Proposal: the model, after Implement. Alternative: tests are written during Plan, before the code, so the model cannot shape them to fit its code.
3. **E2E flows.** Proposal: derived from the brief by the harness as fixed steps (open, fill, click, expect text). Alternative: the model writes them, which lets it write weak ones.
4. **Plan amendments during Implement.** Proposal: the model may change a declaration inside its own task's files freely; a change that touches another task's files sends the work back to Plan.
5. **Setup as a model step.** You suggested the model proposes and installs packages. In this draft the model proposes them in Plan and the harness installs. Letting the model run the install is the alternative.

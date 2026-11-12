# 0001: Flow control is a hybrid state machine with large-model escalation

- **Status:** Accepted, 2026-11-11
- **Layer:** 4 (flow control)

## Context

The harness must decide who chooses the next step: the model or the harness. The model is a 9B fine-tune with thinking disabled. Its measured weak points are long-range self-management, not local code edits (see [research/existing-harnesses-and-model.md](../research/existing-harnesses-and-model.md)):

- It repeats a failed call instead of changing approach.
- It does not reliably judge when work is finished.
- It has been trained on contexts no longer than 16k tokens.

Of the three existing Jac harnesses, the two aimed at small models (`jac ai` and jac-mini-coder) both put the harness in charge of phases.

## Options considered

| Option | Description | Why not chosen |
|---|---|---|
| A. Model-led | The system prompt describes the workflow; the model decides when to plan, test and stop. | Depends on exactly the abilities the model lacks. |
| B. Harness-led | A state machine fixes every step; the model fills one slot per step. | Too rigid for debugging, where the next step depends on what the error says. |
| **C. Hybrid** | The harness owns phases, tasks and gates. Inside a task the model runs its own short loop. | Chosen. |

## Decision

1. **The harness owns the outer loop.** It tracks the current phase and the current task. Phase transitions are triggered by checks the harness runs itself, not by the model saying it is done.
2. **The model owns the inner loop.** Inside one task it chooses its own tool calls, within a step budget and under stall detection.
3. **The workflow and state machine are defined by this project.** They are not inherited from a host harness and not left for the model to invent.
4. **A large "admin" model can be called in to rescue the small model.** When the small model stalls or exhausts its budget, control can pass to a stronger model.

## Consequences

- The harness is more complex than a plain agent loop: it needs phase definitions, gates, a task store and a stall detector.
- Each phase can expose only the tools it needs, which keeps the per-step choice small.
- Every trajectory record must carry its phase and task, because the same model output means different things in different phases.
- Admin interventions are a source of recovery examples, which the existing training data lacks. How they are recorded is part of the trajectory format decision.
- A host harness whose control flow is event callbacks (such as pi) fits this less naturally. This weighs on the build-or-extend decision.

## Still open

- The phase list, each phase's gate and its output artefact.
- What triggers escalation to the admin, what the admin is allowed to do, and how control returns.
- Step budgets and the stall-detection rules.

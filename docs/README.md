# Jach design docs

## Layout

| Path | Contents |
|---|---|
| `ideas/` | Raw ideas from discussion, each tracked until it is decided, parked or dropped. See [ideas/README.md](ideas/README.md). |
| `research/` | Facts gathered before designing. No decisions. |
| `knowledge/` | Summaries of papers and articles, grouped by topic. See [knowledge/README.md](knowledge/README.md). |
| `decisions/` | One file per settled decision: context, options, choice, consequences. |
| `ref/<vendor>/` | Official docs of third-party tools we depend on, saved for offline reference. |

## Research

- [research/pi-harness.md](research/pi-harness.md): what the pi coding agent (1.0.4) lets an extension change
- [research/existing-harnesses-and-model.md](research/existing-harnesses-and-model.md): jacBuilder, the removed `jac ai`, jac-mini-coder, and the fine-tuned model's format and failure modes
- [research/model-status-2026-11-11.md](research/model-status-2026-11-11.md): browser-verified results for v1.35 and the 1112 adapter, and where they fail
- [research/compiler-probe-0.36.1.md](research/compiler-probe-0.36.1.md): experiments on what the 0.36.1 compiler can detect and report; which failure modes are mechanically catchable
- [research/chat-templates.md](research/chat-templates.md): how the Qwen 3.5, Ornith 1.5 and JacLLM templates render earlier reasoning;
- [research/jac-cli-surface.md](research/jac-cli-surface.md): the jac 0.36.1 commands a harness would wrap

## The six layers of a harness

Every design decision below belongs to one of these.

| Layer | Question it answers |
|---|---|
| 1. Model interface | Tool-call format, parsing, what happens on a malformed call |
| 2. Tool set | Which tools, how their schemas are shaped |
| 3. Context assembly | What exactly is sent to the model each turn (folding, dynamic Jac info) |
| 4. Flow control | Who decides what happens next: the model or the harness |
| 5. State and recovery | How work resumes after a stall or interruption (tasks, acceptance criteria) |
| 6. Observability | How each step is logged; this fixes the trajectory dataset format |

## Open decisions

They are listed in the order they should be decided, because earlier ones constrain later ones.

| # | Decision | Layer | Status |
|---|---|---|---|
| 1 | Who drives: model-led, harness-led state machine, or hybrid | 4 | Decided: hybrid, with large-model escalation. [0001](decisions/0001-flow-control-hybrid-state-machine.md) |
| 2 | Primary mode of use: interactive, headless batch, or both | 4, 6 | Decided: both, user chooses. [0002](decisions/0002-interactive-and-auto-modes.md) |
| 3 | Working context budget per task (hard limit is 262,144 tokens; training so far reached 16k) | 3 | Decided: [0005 section 5](decisions/0005-task-format.md) (limit is 262,144; no smaller cap until measured) |
| 4 | SDLC phases, their gates, and the artefact each produces | 4 | Decided: [0004](decisions/0004-sdlc-phases-and-gates.md) |
| 5 | Task format: scope, inputs, outputs, acceptance criteria, resume protocol | 5 | Decided: [0005](decisions/0005-task-format.md) |
| 6 | Tool set and schemas, per phase | 2 | Decided: [0006](decisions/0006-tool-set.md) |
| 7 | Fold and unfold: what a folded turn keeps, how unfold is addressed | 3 | Decided: [0007](decisions/0007-fold-and-unfold.md) |
| 8 | Dynamic Jac information: what is loaded, when, and from where | 3 | Open |
| 9 | System prompt | 1, 3 | Open |
| 10 | Stall detection and recovery (repeated calls, repair budget) | 5 | Proposed: [0010](decisions/0010-stall-detection.md) |
| 10a | Admin escalation: triggers, what the admin may do, how control returns | 4, 5 | Open |
| 11 | Build on pi or from scratch | all | Decided: scratch, in Jac. [0011](decisions/0011-build-from-scratch-in-jac.md) |
| 12 | Trajectory log format | 6 | Decided: [0012](decisions/0012-run-log-format.md) |
| 13 | Which Jac version the harness, training data and evaluation all target | all | Decided: 0.36. [0003](decisions/0003-target-jac-0-36.md) |
| 14 | Evaluation ladder and the definition of a pass | 5, 6 | Open |
| 15 | Which checkpoint lineage to build on, and thinking on or off with what budget | 1 | Open |

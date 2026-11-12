# JacKnife design docs

## Layout

| Path | Contents |
|---|---|
| `research/` | Facts gathered before designing. No decisions. |
| `knowledge/` | Summaries of papers and articles, grouped by topic. See [knowledge/README.md](knowledge/README.md). |
| `decisions/` | One file per settled decision: context, options, choice, consequences. |
| `ref/<vendor>/` | Official docs of third-party tools we depend on, saved for offline reference. |

## Research

- [research/pi-harness.md](research/pi-harness.md): what the pi coding agent (1.0.4) lets an extension change
- [research/existing-harnesses-and-model.md](research/existing-harnesses-and-model.md): jacBuilder, the removed `jac ai`, jac-mini-coder, and the fine-tuned model's format and failure modes
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
| 3 | Working context budget per task (hard limit is 262,144 tokens; training so far reached 16k) | 3 | Under discussion |
| 4 | SDLC phases, their gates, and the artefact each produces | 4 | Open |
| 5 | Task format: scope, inputs, outputs, acceptance criteria, resume protocol | 5 | Open |
| 6 | Tool set and schemas, per phase | 2 | Open |
| 7 | Fold and unfold: what a folded turn keeps, how unfold is addressed | 3 | Open |
| 8 | Dynamic Jac information: what is loaded, when, and from where | 3 | Open |
| 9 | System prompt | 1, 3 | Open |
| 10 | Stall detection and recovery (repeated calls, repair budget) | 5 | Open |
| 10a | Admin escalation: triggers, what the admin may do, how control returns | 4, 5 | Open |
| 11 | Build on pi or from scratch | all | Open; depends on 1 to 3 |
| 12 | Trajectory log format | 6 | Open |

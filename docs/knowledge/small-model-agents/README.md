# Small-model agents

Sources on making small or local models reliable at tool use: interface and tool-schema design, limiting the visible tool set, the effects of constrained decoding, repair of malformed calls at the harness boundary, and what properties of fine-tuning data matter for agent behaviour. All files were written from pages fetched on 2026-11-11; each file states how much of the source was read.

| File | One-line takeaway |
|---|---|
| [swe-agent-aci.md](swe-agent-aci.md) | Interface design alone moved SWE-bench Lite from 11% to 18%; after one failed edit, eventual edit success drops from 90.5% to 57.2%. |
| [anthropic-writing-tools-for-agents.md](anthropic-writing-tools-for-agents.md) | Few high-level tools, unambiguous parameter names, readable identifiers, and errors that show a valid call; measured by task evaluations. |
| [less-is-more-tool-reduction.md](less-is-more-tool-reduction.md) | Showing 1.5B-8B models fewer tools improved tool selection and cut latency 48-80%; 4-bit quantisation alone roughly halved accuracy for one model. |
| [agent-flan.md](agent-flan.md) | Models overfit the format of agent data; convert to chat, weight reasoning data, and add a few hundred negative samples to cut hallucinated tool calls. |
| [learning-from-failure-negative-examples.md](learning-from-failure-negative-examples.md) | Tagged failed trajectories from a strong model help when positives are scarce; failed trajectories from a weak model hurt by 3-6 points. |
| [swe-smith.md](swe-smith.md) | ~5k filtered teacher trajectories give 40% (32B) and 15% (7B) on SWE-bench Verified; the student loops far more than the teacher and nudges do not fix it. |
| [let-me-speak-freely-format-restrictions.md](let-me-speak-freely-format-restrictions.md) | Forced structure costs reasoning accuracy (about 16 points for an 8B model on GSM8K) but helps closed-set choices; reason first, format second. |
| [constraint-tax.md](constraint-tax.md) | For models up to 3B, schema-constrained decoding gave 100% valid output and lower correctness; one tool-call task fell from 91.5% to 48.0%. |
| [small-model-database-agent.md](small-model-database-agent.md) | 36% of small-model agent failures were tool calls that never executed; tolerant parsing and argument repair took 8B models from failing to mostly passing. |

Related material filed elsewhere: `stuck-in-a-loop/feedback-that-backfires.md` (how small models react to error feedback) and the three DAgger-style papers under `escalation/` (training on recovery states).

## Patterns across sources

- Interface changes are large and cheap relative to model changes. SWE-agent (+7 points from tools), the database-agent study (0/30 to 21/30 from server fixes) and the Anthropic post all report sizeable gains with the model fixed. Only SWE-agent's are controlled ablations.
- Fewer tools and fewer parameters. SWE-agent, Anthropic and Less-is-More agree; Less-is-More shows the effect is strongest for small quantised models.
- Guard the boundary. SWE-agent rejects edits that fail lint; the database-agent study repairs near-miss calls. One rejects, the other repairs. They are compatible: repair what is unambiguous, reject the rest with a specific message.
- Syntax validity is not correctness. Two papers find that constrained decoding lowers answer quality on reasoning-dependent outputs, and the Constraint Tax shows this for tool-call arguments in models up to 3B. Both recommend free reasoning before a constrained step. Neither tested a model of exactly our size on a coding tool call, so this needs local measurement.
- Constraints do help closed-set choices (Let Me Speak Freely's classification results), which supports constraining tool names and enumerated arguments while leaving room to reason.
- Error-feedback advice is not uniform. SWE-agent and Anthropic recommend detailed, actionable errors; `feedback-that-backfires.md` finds that for very small models the wording barely matters and echoing the failed call is harmful. A consistent reading: say what a valid call looks like, without repeating the invalid one.
- Training data: filter to successful trajectories (SWE-smith), prefer diversity to volume (SWE-smith, Agent-FLAN), and include examples of not acting (Agent-FLAN). Fine-tuned students inherit the teacher's successes but not its recoveries, and loop more (SWE-smith).
- The sources differ on failed trajectories. Learning From Failure finds tagged failures from a strong model useful; SWE-smith and the DAgger-style papers find success filtering better, and everyone who tested it found the weak model's own trajectories harmful. The settings differ (question answering against coding), so the disagreement is unresolved for our case.
- Gaps: no source here evaluates grammar-constrained tool calling on a 7-9B coding agent, and none reports a small-model agent benchmark specific to an uncommon language such as Jac. SWE-smith's multilingual result (8.4% against 6.5% for the base model) suggests transfer from Python data is weak.

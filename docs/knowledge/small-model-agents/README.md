# Small-model agents

Sources on making small or local models reliable at tool use: the design of commands and tool schemas, how many tools to show, what constrained decoding and format restrictions do to answer quality, and repairing malformed calls at the harness boundary. Most of the evidence comes from models far from ours: closed frontier models (SWE-agent, Anthropic) or models of 3B and below (Constraint Tax). Only Less-is-More, Let Me Speak Freely and the database-agent study include 7-9B open models, and none includes a model fine-tuned on its own tool format. All numbers were checked against the source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [swe-agent-aci.md](swe-agent-aci.md) | A | Interface changes alone took GPT-4 Turbo from 11.0% to 18.0% on SWE-bench Lite; after one failed edit, eventual edit success fell from 90.5% to 57.2%. |
| [anthropic-writing-tools-for-agents.md](anthropic-writing-tools-for-agents.md) | D | Few workflow-level tools, unambiguous parameter names, readable identifiers, errors that show a valid input, all tuned by task evaluations. |
| [less-is-more-tool-reduction.md](less-is-more-tool-reduction.md) | B | Showing 1.5-8B models only the top 3-5 tools cut latency up to 80%; for Llama 3.1 8B, quantisation alone cut BFCL accuracy from 63.0% to 20.4-44.4%. |
| [let-me-speak-freely-format-restrictions.md](let-me-speak-freely-format-restrictions.md) | B | Schema instructions cut GSM8K accuracy (LLaMA-3-8B 75.1 to 48.9) but helped closed-set classification; real schema decoding on GPT-4o-mini stayed close to free text. |
| [constraint-tax.md](constraint-tax.md) | B | In models up to 3B, hard schemas made output 100% valid and more often wrong; a calendar tool call fell from 91.5% to 48.0% executable accuracy. |
| [small-model-database-agent.md](small-model-database-agent.md) | C | 75.7% of small-model agent losses came from runs that did use tools; five server-side repair rules moved six models by 6-21 of 30 cells. |

## Patterns across sources

- **The interface moves results as much as the model does.** SWE-agent (+7 points over a shell, controlled ablations), the database-agent study (0/30 to 21/30 for cogito:8b, uncontrolled) and the Anthropic post (no numbers) all report large gains with the model fixed. Only SWE-agent's comes from an ablation, and it was measured on closed frontier models. Rests on A, C and D.
- **Make parameters impossible to misread.** SWE-agent's edit takes the line numbers its viewer prints, which the authors say removes the arithmetic models get wrong. The Anthropic post asks for unambiguous names and strict data models. The database study found wrong field names and displaced values to be the main transport failure. This applies directly to our zero-based offset. The SWE-agent part is a design rationale, not an ablation. Rests on A, C and D.
- **A clear error message is not enough for a model that does not self-correct.** In SWE-agent, edit success after one failure dropped from 90.5% to 57.2% even with a detailed rejection message (GPT-4 Turbo). In the database study, one model resent the same displaced shape four times after being told which fields were missing. `../stuck-in-a-loop/feedback-that-backfires.md` finds that the failed call in context makes a repeat more likely. What helped in the database study was changing what the server accepts. A consistent reading: repair what is unambiguous, reject the rest with the valid form, and do not echo the failed call. The evidence that repair works rests on C.
- **The sources disagree on constrained decoding, and the numbers depend on model size and implementation.**

  | Source | Model | Free / prompt-only | Constrained | Note |
  |---|---|---|---|---|
  | Constraint Tax | Qwen2.5-1.5B, calendar tool call | 91.5% exec. | 48.0% exec. | both 100% valid |
  | Constraint Tax | sub-3B suite | 19.7% answer, 12.0% exec. | 11.0% answer, 11.0% exec. | SmolLM2 gained |
  | Constraint Tax | Qwen2.5-3B | 39.0% answer | 23.7% answer | |
  | Let Me Speak Freely | GPT-4o-mini, GSM8K | 94.57 | 91.71 (schema decoding), 86.95 (JSON mode) | |
  | Let Me Speak Freely | GPT-4o-mini, Last Letter | 83.11 | 86.07 (schema decoding), 76.00 (JSON mode) | constrained beat free text |
  | Let Me Speak Freely | LLaMA-3-8B, Last Letter | 70.1 | 7.56 (JSON mode) | JSON mode put the answer key first |

  Both papers find that putting reasoning before the answer, as a free-text step or a rationale field, removes most of the loss. Neither tests a 7-9B model with real grammar-constrained tool calls. Rests on B only.
- **Constraints help where the answer is a closed choice.** Let Me Speak Freely's classification tasks improved under JSON (DDXPlus: Gemma-2-9B 22.9 to 53.0). This supports constraining tool names and enumerated arguments, and validating free-form values in the harness. Rests on B.
- **Fewer tools per step.** SWE-agent, Anthropic and Less-is-More agree. Less-is-More's gain sizes are only in figures, and its baseline used a larger context. Rests on A, B and D.
- **Measure under deployment conditions.** Quantisation changed Llama 3.1 8B's tool-call accuracy from 63.0% to as low as 20.4% (Less-is-More). An uncapped context made a working 3B model read 0/5 (database study). Constrained-decoding results differed between serving backends for one model (Constraint Tax). Rests on B and C.
- **Training data (see also).** `../trajectory-data/swe-smith.md` reports that students trained on filtered teacher trajectories loop more than their teacher. `../trajectory-data/agent-flan.md` reports that negative examples cut hallucinated tool calls. `../trajectory-data/learning-from-failure-nat.md` reports that tagged failures from a strong model help when successes are scarce, while failures from a weak model hurt. Those notes are owned by `trajectory-data/`; their numbers were not re-checked here.

## Gaps

- No source tests grammar-constrained tool calls on a 7-9B model, or on any model fine-tuned on its own call format.
- No source measures tool use with reasoning disabled against enabled. That is our baseline setting, and every "reason first" result assumes a reasoning span is available.
- No source measures self-correction rates on small models after a parameter error, or how argument repair affects later turns. For example, does a repaired call teach the model anything within the run?
- No source covers an uncommon target language such as Jac, or a linter guardrail for a language without mature tooling.
- No source compares widening the tool set after a failure (Less-is-More's fallback) with narrowing it.

## See also

- [../trajectory-data/agent-flan.md](../trajectory-data/agent-flan.md)
- [../trajectory-data/swe-smith.md](../trajectory-data/swe-smith.md)
- [../trajectory-data/learning-from-failure-nat.md](../trajectory-data/learning-from-failure-nat.md)
- `../stuck-in-a-loop/feedback-that-backfires.md` (how small models react to error feedback)

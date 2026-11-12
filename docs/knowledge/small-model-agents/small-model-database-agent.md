# Transport Failures and Server-Side Argument Repair in Small-Model Agents

A method note based on "What Stops a Small Language Model From Driving a Database Agent" [1].

- **Evidence:** C. Field observations of one production system with the full run data released; the authors state it is not an ablation, and they maintain the software under test.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML.

## 1. Problem

Small models are commonly assumed to fail at agent work for lack of reasoning, which predicts runs where the model never acts. The authors test this on the agent mode of an open-source SQL client, LibreDB Studio, driven by 39 locally served models (tags from about 1.7B to 35B, through Ollama) and one hosted control. [1, Abstract, §1]

## 2. Method

Each failed run is put in one class by what the run ledger shows, applied in this order. [1, §4.4]

| Class | Definition |
|---|---|
| Clock | Ended by model timeout, turn limit or run deadline |
| Capability | Invoked no tool at all |
| Verification | Filed a report that the verifier rejected |
| Transport | Used tools, did not time out, never got a deliverable through |

The authors then logged the arguments of refused calls (normally never recorded) and changed only the server. [1, §4.3, §7]

### Key decisions

1. **Classify by what the run did.** "Process exited successfully" is not a pass: 1,405 of 2,204 model-stopped runs were unanswered. [1, §3]
2. **Read a model in one sitting.** Two models recorded at 30/30 across days and settings scored 22/30 and 23/30 when re-read under one configuration. [1, §4.1]
3. **Record refused arguments.** Without them, a refusal shows which field was missing but not where the model put it. [1, §4.3]
4. **Repair only what is unambiguous.** Exactly one missing and one surplus key is treated as a rename; a lone object becomes a one-item list; nested calls are still refused with a message. [1, Table 7]

### Implementation details that generalise

- Recognise a tool call written in the text channel by its tool name, not by a strict JSON parse. [1, Table 7]
- A refusal should not say "remove" for a field that belongs to a sibling tool; it should say where the field goes. [1, §6.3, Table 7]
- Cap the serving context explicitly and check the context the serving engine actually holds. [1, §8.1]

## 3. Evidence

Corpus: 8,199 runs, 14,008 refused calls, 2,100 model-attributed agent-mode losses. [1, §5.1, Table 2]

| Class | Share (adopted order) | Share (capability first) |
|---|---|---|
| Transport | 36.2% | 36.2% |
| Clock | 25.8% | 18.8% |
| Verification | 20.7% | 20.7% |
| Capability | 17.3% | 24.3% |

[1, §5.3, Table 4]

- 75.7% [73.8, 77.5] of losses came from runs that invoked at least one tool. This held in 99.7% of resamples clustered by model. [1, §8.6]
- The class ordering is weaker. Clustered by model, the transport interval is [22.0, 49.1], and transport is the largest class in only 74.5% of resamples. [1, §8.6]
- Of 69 stopping turns examined, 27 held a complete tool call written as text; none parsed as JSON, and 24 failed the same way, an array closed twice. [1, §6.1]
- One model sent the same displaced shape four times after being told which three fields were missing (SQL in the `change` field, `reason` for `rationale`, one evidence object instead of a list). Only one pair of calls in all captures was byte-identical. [1, §6.2]

Five server changes; same models, prompts, sampling and tasks. Passes out of 30. [1, §7, Table 8]

| Model | Before | After |
|---|---|---|
| granite4.2:3b | 21 | 28 |
| mistral-nemo:12b | 18 | 26 |
| llama3.1:8b | 10 | 24 |
| cogito:8b | 0 | 21 |
| glm4 | 0 | 16 |
| deepseek-r1:8b | 18/28 | 24/28 |

- The text-channel fix alone, on four cells, gave +1, 0, 0, −1. The argument-shape fixes moved the table. [1, §7]
- With no context cap, a 12B model (7.1 GB on disk) held 51 GB at a 262,144-token window. A 3B model's planning cell read 0/5 uncapped and 5/5 at 32,768. [1, §8.1]

## 4. Evidence boundaries

- **Not an ablation.** Cells were re-read because they scored low, so regression to the mean predicts gains. Part of the gain for three models came from invalid earlier readings. Six of six improving gives a sign-test p = 0.031. [1, §7, §8.6]
- **All §5 figures were taken before the context cap,** so clock failures are inflated by an unknown, model-dependent amount. [1, §8.1]
- One machine, one small database, one harness; run counts per model ranged from 3 to 629. [1, §8.3, §8.4]
- Read-only database work, not code editing; no model was fine-tuned on the tool format.
- The authors are contributors to the software evaluated. [1, Conflict of interest]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Before calling our model's parameter misuse a model limit, audit the tool. Is the parameter's meaning (zero- or one-based) stated and the same across tools, and does the refusal say exactly what to send?
- A message that names the fix did not stop repeats here, as `../stuck-in-a-loop/feedback-that-backfires.md` predicts. For a model that never self-corrects, accepting and repairing unambiguous near-misses is more likely to help than better wording.
- Logged repairs (malformed call, canonical call) are candidate training pairs, if the harness format is what we train on.

## Reference

[1] Cevheri Bozoğlan, Yusuf Gündoğdu, Abdullah Kaya, Koray Şirin (independent researchers; contributors to LibreDB Studio). *What Stops a Small Language Model From Driving a Database Agent.* arXiv:2609.21341, 18 September 2026. <https://arxiv.org/html/2609.21341>. Data: <https://doi.org/10.57967/hf/10485>. Accessed 2026-11-11.

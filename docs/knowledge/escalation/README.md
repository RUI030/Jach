# Escalation

Sources on combining a small model with a large one. They cover three questions our admin-model design must answer: when the large model is called (cascades, routers, self-checks, consult points), what it does once called (advise, plan and decompose, describe the edit, take over, or correct offline), and how its interventions become training data for the small model (DAgger and its adaptations to LLM agents). All notes were rewritten on 2026-11-11 with numbers checked against the primary source text.

| Note | Grade | One-line takeaway |
|---|---|---|
| [frugalgpt.md](frugalgpt.md) | B | Cascade with a small learned scorer per stage; 59-98% cost saving at equal accuracy on single-turn classification and QA. |
| [routellm.md](routellm.md) | B | Route before the weak model runs; needs in-domain labels, and savings fall from 3.66× (chat) to about 1.4× (MMLU, GSM8K). |
| [automix.md](automix.md) | B | Small model's context-grounded self-check is a noisy signal; a learned router over it had positive cost-efficiency gain in all 15 settings, but the check was uninformative on 2 of 5 datasets. |
| [anthropic-advisor-tool.md](anthropic-advisor-tool.md) | C (numbers D) | Strong model reads the full transcript and returns a few hundred tokens of advice; weak executors under-call it, so consult points must be forced. |
| [aider-architect-editor.md](aider-architect-editor.md) | D | Separating "describe the fix" from "format the edit" raised scores 3-5 points even with one model in both roles. |
| [minions-local-cloud-collaboration.md](minions-local-cloud-collaboration.md) | B | Large model decomposes into single-step jobs for the small one: 97.9% of quality at 18% of cost with 8B; free chat between them reached 87%. |
| [dagger-original.md](dagger-original.md) | A | Label the states the learner itself reaches with expert actions, aggregate, retrain; errors then grow linearly, not quadratically, with horizon. |
| [on-policy-expert-corrections.md](on-policy-expert-corrections.md) | B | Student starts, expert takes over, train on the expert part only; at 7B, skipping the loop filter left the model worse than untrained. |
| [dagger-llm-agents.md](dagger-llm-agents.md) | B | Turn-level teacher mixing with teacher labels on every state beat SFT, RL and on-policy distillation at 4B and 8B on SWE-bench Verified. |
| [leap-privileged-feedback.md](leap-privileged-feedback.md) | B | Teacher with hidden information corrects failed trajectories offline; corrections must be reachable from what the student saw. |

Related material filed elsewhere: `stuck-in-a-loop/empirical-study-issue-solving-failures.md` (Expert-Executor review agent) and `stuck-in-a-loop/openrouter-doom-loop-detection.md` (escalation to a stronger model as a loop response).

## Intervention designs compared

| Design (note) | Who triggers | What the strong model does | How control returns | Data it yields |
|---|---|---|---|---|
| Cascade (FrugalGPT, AutoMix) | Learned scorer or router after the small model answers | Answers the query from scratch | No return; strong answer is final | (query, small answer, accept/escalate) labels for the router |
| Predictive router (RouteLLM) | Router, before any model runs | Answers the whole query | No return | (query, which model won) labels |
| Advisor (advisor tool) | The executor itself, steered by prompt or a harness nudge | Reads the transcript, returns short advice; never acts | Immediately; executor continues the same turn | (transcript, advice) pairs; no executor action labels |
| Architect / editor (Aider) | Fixed: every task | Describes the change in prose | Editor turns the prose into edits | (task, description, edit) triples |
| Decomposition (Minions) | Fixed: every round | Writes single-step jobs, then aggregates outputs | Small model runs each job; strong model decides on another round | (job, chunk, small answer) records; none used for training |
| Takeover to completion (OEC; AggreVaTe-style in Revisiting DAgger) | Random switch turn (OEC) or sampled prefix length | Acts in the environment until the end | Does not return | Student prefix plus expert continuation; train on expert turns only |
| Turn-level mixing (Revisiting DAgger; original DAgger) | Coin flip per turn with probability β | Acts on some turns; labels every turn | Next turn, by coin flip | Expert label on every visited state |
| Offline correction (LEAP) | After the run, on failed trajectories | Rewrites reason and action per step, using privileged info it must not reveal | Not live; the student is retrained | Corrected (history, reason, action) for every step of a failed run |

## Patterns across sources

- **The escalation decision needs a signal from outside the small model's own judgement.** FrugalGPT trains a scorer, RouteLLM a router, AutoMix a router over a self-check it treats as noisy. The advisor docs report that weaker executors under-call when left to decide (≈7-point gain from a nudge on Haiku), but that rests on grade C/D vendor evidence.
- **Routing before versus after the attempt are different designs.** RouteLLM predicts from the query; FrugalGPT and AutoMix judge the output. All three evaluate single-turn tasks, so none covers a mid-task trigger in a multi-turn agent.
- **Reported savings vary by an order of magnitude with the task.** 98.3% on HEADLINES classification against 59.2% on COQA (FrugalGPT); 3.66× on MT Bench against 1.41× on MMLU (RouteLLM). Large numbers come from workloads with many easy items.
- **Help can be much cheaper than takeover.** The advisor returns 400-700 text tokens (C/D); Aider's architect writes a description and a cheaper model edits (D); Minions' remote model never reads the documents (B). Only Minions has a controlled comparison.
- **Structure beats free conversation between models.** Minions' free chat reached 87% of remote accuracy, its structured decomposition 97.9% (B). Aider's gain comes from a fixed two-step split (D).
- **Training on interventions: label student-reached states with expert actions, train by plain SFT.** Original DAgger (A), OEC, Revisiting DAgger and LEAP (B) agree. OEC and Revisiting DAgger agree that training on the student's own trajectories is weak or harmful: at 32B OEC found it "severely decreased" performance, and GRPO from the base model gained under 1 point at 4B and 8B.
- **They differ on how the expert is involved, and only one compares options.** Revisiting DAgger found turn-level mixing better than takeover after a student prefix (29.8% against 27.3% at 8B, no variance reported). OEC used only takeover and found it better than pure imitation (961 OEC plus 961 expert trajectories resolved 4.6 points more than 2,000 expert trajectories at 32B). LEAP used only offline correction. No source compares all three under one setup.
- **Data hygiene decides the outcome at small scale.** Without its loop filter OEC's 7B model scored 11% against 13.3% untrained; LEAP found a teacher leaking privileged facts produced a worse student than a cautious one. Both are B.

## Gaps

- No source triggers the strong model on a failure signal from the harness (checker error, repeated calls, loop detector). Every trigger studied is a learned scorer, a self-check, a random switch, a fixed schedule, or the executor's own choice.
- No source tests a student near 9B fine-tuned on a niche language, or a teacher much larger than the student in an agent loop (the closest pair is Qwen3-8B with a 30B teacher).
- No source compares advice, rewrite-the-task and takeover on the same tasks, or measures which one yields better training data.
- No source covers handing control back after a short intervention and measuring whether the small model then stays on track.
- No source says how to record an intervention when the strong model's output (advice, a plan) is not an action in the small model's format.
- None reports variance across seeds for the agent-training results.

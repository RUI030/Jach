# Escalation

Sources on combining a small model with a large one: deciding when the large model is needed (cascades and routers), what form its help takes (advice, planning, edit description, takeover), and how its interventions can become training data for the small model (DAgger and its adaptations to LLM agents). All files were written from pages fetched on 2026-11-11; each file states how much of the source was read.

| File | One-line takeaway |
|---|---|
| [frugalgpt.md](frugalgpt.md) | Cascade with a small learned scorer deciding accept-or-escalate; 59-98% cost savings at equal accuracy on single-turn tasks. |
| [routellm.md](routellm.md) | Predictive strong/weak routing with one threshold; needs in-distribution labels, gains from 3.66x (chat) down to ~1.4x (MMLU, GSM8K). |
| [automix.md](automix.md) | Small model self-verifies against context, a learned router treats that as a noisy signal; calibration failed on 2 of 5 datasets. |
| [anthropic-advisor-tool.md](anthropic-advisor-tool.md) | Strong model reads the full transcript and returns short advice; weak executors under-call it, so consult points need forcing. |
| [aider-architect-editor.md](aider-architect-editor.md) | Separating "describe the solution" from "format the edit" raised benchmark scores 3-10 points, even when one model plays both roles. |
| [minions-local-cloud-collaboration.md](minions-local-cloud-collaboration.md) | Large model decomposes into single-step jobs for an 8B local model: ~98% of quality at ~18% of cost; free-form chat between the two did worse. |
| [dagger-original.md](dagger-original.md) | The founding statement of the problem: policies trained on expert data never see the states their own mistakes cause (abstract only). |
| [on-policy-expert-corrections.md](on-policy-expert-corrections.md) | Student starts, expert finishes, train on the expert part only; must filter repetitive trajectories and mask the student prefix. |
| [dagger-llm-agents.md](dagger-llm-agents.md) | DAgger with Qwen3 4B/8B coding agents: 27.3% / 29.8% on SWE-bench Verified against 22.9% / 23.4% for plain fine-tuning. |
| [leap-privileged-feedback.md](leap-privileged-feedback.md) | A teacher with privileged information corrects student trajectories offline; an 8B student surpassed the unassisted GPT-4o teacher on two of three benchmarks. |

Related material filed elsewhere: `stuck-in-a-loop/empirical-study-issue-solving-failures.md` (Expert-Executor review agent) and `stuck-in-a-loop/openrouter-doom-loop-detection.md` (escalation to a stronger model as a loop response).

## Patterns across sources

- The escalation decision needs an external signal. FrugalGPT trains a scorer, RouteLLM a router, AutoMix a meta-verifier over noisy self-checks. None relies on the small model simply declaring it needs help, and the advisor documentation reports that weaker executors under-call when left to decide.
- Before-the-fact routing and after-the-fact cascading are different designs. RouteLLM predicts difficulty from the query; FrugalGPT and AutoMix judge the small model's output. For multi-turn agents neither paper applies directly, since all three evaluate single-turn tasks.
- Reported savings vary widely by task (1.4x to 50x). The large numbers come from classification-like tasks with many easy items. Expect smaller gains on harder workloads.
- Help can be much cheaper than takeover. The advisor tool returns a few hundred tokens of advice; Aider's architect writes a description and a cheap model edits; Minions' cloud model writes a decomposition and never reads the documents.
- Structure beats conversation between models. Minions' free chat recovered 87% of quality, its structured decomposition 98%. Aider's gain comes from a fixed two-step split.
- Small-model weaknesses named independently: compound instructions and long context (Minions), reasoning and formatting in one output (Aider).
- For training on interventions, three papers agree on the core: label the states the student actually reaches with expert actions, and train on those labels by plain supervised fine-tuning. They also agree that training on the student's own actions is harmful or useless, even when the run succeeded.
- They differ on how the expert is involved: takeover to completion (OEC), per-turn mixing with labels on every state (Revisiting DAgger, which found this better than takeover), or offline correction with privileged information (LEAP). No source compares all three under one setup.
- Data hygiene is decisive at small scale: OEC's 7B model got worse than untrained when repetitive trajectories were left in the data.

# Escalation

Sources on combining a small model with a large one. They cover three questions our admin-model design must answer: when the large model is called (cascades, routers, self-checks, consult points), what it does once called (advise, plan and decompose, describe the edit, take over, or correct offline), and how its interventions become training data for the small model (DAgger and its adaptations to LLM agents). All notes were rewritten on 2026-11-11 with numbers checked against the primary source text.

| Note | Grade | One-line takeaway |
|---|---|---|
| [frugalgpt.md](frugalgpt.md) | B | Cascade with a small learned scorer per stage; 59-98% cost saving at equal accuracy on single-turn classification and QA. |
| [routellm.md](routellm.md) | B | Route before the weak model runs; needs in-domain labels, and savings fall from 3.66× (chat) to about 1.4× (MMLU, GSM8K). |
| [aider-architect-editor.md](aider-architect-editor.md) | D | Separating "describe the fix" from "format the edit" raised scores 3-5 points even with one model in both roles. |
| [minions-local-cloud-collaboration.md](minions-local-cloud-collaboration.md) | B | Large model decomposes into single-step jobs for the small one: 97.9% of quality at 18% of cost with 8B; free chat between them reached 87%. |
| [dagger-original.md](dagger-original.md) | A | Label the states the learner itself reaches with expert actions, aggregate, retrain; errors then grow linearly, not quadratically, with horizon. |
| [on-policy-expert-corrections.md](on-policy-expert-corrections.md) | B | Student starts, expert takes over, train on the expert part only; at 7B, skipping the loop filter left the model worse than untrained. |
| [dagger-llm-agents.md](dagger-llm-agents.md) | B | Turn-level teacher mixing with teacher labels on every state beat SFT, RL and on-policy distillation at 4B and 8B on SWE-bench Verified. |

Related material filed elsewhere: `stuck-in-a-loop/empirical-study-issue-solving-failures.md` (Expert-Executor review agent) and `stuck-in-a-loop/openrouter-doom-loop-detection.md` (escalation to a stronger model as a loop response).

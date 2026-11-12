# Task decomposition

How coding agents split work into units that fit a context window, carry the plan between stages, decide when a unit is done, and resume after a break. The sources fall into two groups. Four papers measure something (AgentCoder, the TDD study, MetaGPT, Plan-and-Act), all on frontier or 33B-plus models and none at repository scale. Four describe how a system works without measuring whether it works better: Anthropic's harness blog (D) and the Spec Kit, Kiro and LangGraph documentation (C). All notes were checked against the raw source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [agentcoder.md](agentcoder.md) | B | Tests written from the spec in a separate context, run by a script: 79.9 vs 71.3 pass@1 against one agent writing both (HumanEval, GPT-3.5). |
| [tdd-for-code-generation.md](tdd-for-code-generation.md) | B | Tests in the prompt, then a bounded repair loop; the weaker 70B model gained about 1.5–2× as much as GPT-4, and repair attempts after the fourth solved nothing. |
| [metagpt-sop.md](metagpt-sop.md) | B | A fixed role pipeline with schema-defined documents; planning roles lifted executability from 1.0 to 4.0 on two tasks, but a 33B backend scored 1.4 of 4. |
| [plan-and-act.md](plan-and-act.md) | B | Untrained plans hurt a trained executor; plans recovered from successful trajectories plus replanning reached 53.94 on WebArena-Lite, and an 8B model trained with reasoning traces matched the 70B without them. |
| [anthropic-long-running-harnesses.md](anthropic-long-running-harnesses.md) | D | A JSON feature list with pass flags, one feature per session, and a fixed start-up routine that checks the build before new work. No measurements. |
| [github-spec-kit.md](github-spec-kit.md) | C | Spec, plan, tasks as templated files with clarification markers, self-check lists, phase gates and test-first order. No measurements. |
| [kiro-specs.md](kiro-specs.md) | C | EARS acceptance criteria, a bugfix template that records behaviour to preserve, and dependency waves for tasks. No measurements. |
| [langgraph-graph-and-persistence.md](langgraph-graph-and-persistence.md) | C | Typed state with per-key merge rules, conditional edges, checkpoints at step boundaries; a resumed node re-runs from its start, so steps must be idempotent. |

## Patterns across sources

- **Planning artefacts live in files with a fixed structure, not in the conversation.** Spec Kit, Kiro, MetaGPT and the Anthropic harness all pass named documents between stages. Only MetaGPT measures anything about it (B, on seven and two tasks); the rest is C and D.
- **The checker should be separate from the author.** AgentCoder shows tests written in the same conversation as the code are less accurate (61.0 vs 87.8 on HumanEval) and give lower pass@1 (B). Anthropic reports premature "done" claims fixed by end-to-end testing, but still lets the agent set its own status (D). None of the sources puts the done decision fully outside the model.
- **Executable feedback helps, and its returns run out within a few rounds.** MetaGPT's feedback added 4.2 and 5.4 points with a three-retry cap; the TDD study found no fifth-attempt successes; AgentCoder was still gaining 1.2 points at its fifth and last iteration. The sources disagree on where the curve flattens, and none tested more than five rounds.
- **Tests in the prompt help weaker models more.** The TDD study's Llama 3 70B gained 38.6 and 21.95 points against GPT-4's 18.04 and 14.64 (B). On harder, file-level problems, repair helped more than supplying tests (4.18 vs 3.09 points).
- **How much to fix up front is contested.** Spec Kit and Kiro front-load requirements and design (C). Plan-and-Act found untrained static plans made a trained executor worse (36.36 to 17.16) and replanning gave the largest single gain, 10.31 points (B). Kiro's own Quick Spec skips the review gates. The measured evidence favours fixed criteria with a revisable task list.
- **Procedure does not rescue a weak model.** MetaGPT with Deepseek Coder 33B scored 1.4 of 4 against 3.8 for GPT-4 on five tasks (B). Plan-and-Act got an 8B model to parity only by fine-tuning it on domain plan data with reasoning traces (B).
- **Resume is defined mechanically, never measured.** The Anthropic start-up routine (D) and LangGraph's checkpoint and re-execution rules (C) say how to resume. No source measures resume success.

## Gaps

- No source tests task decomposition, plan files or acceptance criteria with a model near 9B, or with a model fine-tuned on a niche language.
- No source measures how task size or hand-off format affects success after a context reset or resume.
- No source compares a harness-set done status with a model-set one.
- All measured results are single-function benchmarks or web navigation; none covers multi-file applications that must work end to end in a browser.
- No source measures whether a structured criteria format (EARS, checklists) is produced more reliably by a small model than free text.
- How to detect and handle a wrong generated test is raised (AgentCoder, about one test in ten wrong with GPT-4) but not studied.

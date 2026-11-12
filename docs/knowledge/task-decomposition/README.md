# Task decomposition

How coding agents split work into units that fit a context window, carry the plan between stages, decide when a unit is done, and resume after a break. The sources fall into two groups. Four papers measure something (AgentCoder, the TDD study, MetaGPT, Plan-and-Act), all on frontier or 33B-plus models and none at repository scale. Four describe how a system works without measuring whether it works better: Anthropic's harness blog (D) and the Spec Kit, Kiro and LangGraph documentation (C). All notes were checked against the raw source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [agentcoder.md](agentcoder.md) | B | Tests written from the spec in a separate context, run by a script: 79.9 vs 71.3 pass@1 against one agent writing both (HumanEval, GPT-3.5). |
| [metagpt-sop.md](metagpt-sop.md) | B | A fixed role pipeline with schema-defined documents; planning roles lifted executability from 1.0 to 4.0 on two tasks, but a 33B backend scored 1.4 of 4. |
| [anthropic-long-running-harnesses.md](anthropic-long-running-harnesses.md) | D | A JSON feature list with pass flags, one feature per session, and a fixed start-up routine that checks the build before new work. No measurements. |

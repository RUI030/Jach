# Task decomposition

How long-horizon coding agents split work into units that fit a context window and can be resumed: spec-driven workflows (requirements, design, tasks), feature lists with pass flags, harness-owned workflows with typed hand-offs, checkpointed state graphs, plan-then-execute with replanning, and test-driven loops. All files were written from sources fetched and read on 2026-11-11.

| File | One-line takeaway |
|---|---|
| [anthropic-long-running-harnesses.md](anthropic-long-running-harnesses.md) | An initializer writes a feature list with pass flags; each later session does one feature after a fixed start-up routine. |
| [github-spec-kit.md](github-spec-kit.md) | Specify, plan, tasks as three templated files, with uncertainty markers, self-check lists and test-first ordering. |
| [kiro-specs.md](kiro-specs.md) | Requirements in EARS sentences, then design, then dependency-ordered tasks; a separate template for bug fixes. |
| [metagpt-sop.md](metagpt-sop.md) | A fixed procedure with schema-defined documents between roles; planning roles and test feedback both measurably help. |
| [agentcoder.md](agentcoder.md) | Tests written without seeing the code, executed by a script; separation is worth about 8-10 points in ablation. |
| [langgraph-graph-and-persistence.md](langgraph-graph-and-persistence.md) | Typed state with merge rules, conditional edges, checkpoints at step boundaries; resumed nodes re-run from their start. |
| [plan-and-act.md](plan-and-act.md) | Static plans help little; replanning after new observations and synthetic plan data each add about 10 points. |
| [tdd-for-code-generation.md](tdd-for-code-generation.md) | Giving tests up front helps more than the repair loop, and helps weaker models most; repair flattens after 3-4 rounds. |

## Patterns across sources

- **Agreement: planning artefacts live in files with a fixed structure.** Spec Kit, Kiro, MetaGPT and Anthropic's harness all pass named documents between stages. None relies on the conversation to carry the plan.
- **Agreement: the unit of work is small and independently verifiable.** One feature per session (Anthropic), discrete tasks (Kiro, Spec Kit), one file or function (MetaGPT, AgentCoder). Each unit has its own check.
- **Agreement: acceptance criteria must be executable or at least testable.** Feature entries carry verification steps (Anthropic), EARS criteria (Kiro), contracts and test-first ordering (Spec Kit), tests in the prompt (TDD paper).
- **Agreement: the model should not grade its own work unaided.** Anthropic reports premature "done" claims; AgentCoder shows tests written alongside the code are weaker; the remedy in each case is an external executor and a status the agent cannot freely set.
- **Agreement: cap repair loops.** MetaGPT uses three retries, the TDD paper finds diminishing returns after three or four, AgentCoder's gains flatten by five.
- **Disagreement: how much up-front specification.** Spec Kit and Kiro front-load requirements and design; Plan-and-Act finds static plans weak and replanning essential; Kiro itself offers a no-gate quick path. A reasonable reading is: specify the criteria up front, allow the task list to change.
- **Disagreement: who owns control flow.** MetaGPT, LangGraph and Anthropic's harness fix the sequence in code. Spec Kit and Kiro are driven by a human invoking stages. Plan-and-Act lets a model replan every step. For a small model the code-owned variants look the safer choice, but these sources give little direct evidence for small models in a code-owned coding workflow.
- **Gap.** Resume after interruption is described operationally (Anthropic's start-up routine, LangGraph's checkpoint semantics) but no source measures how task granularity or hand-off format affects success after a context reset.

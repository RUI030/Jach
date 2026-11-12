# Equipping agents for the real world with Agent Skills

- **Source:** https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- **Authors / org:** Barry Zhang, Keith Lazuka, Mahesh Murag (Anthropic)
- **Date:** 2025-10-16
- **Type:** engineering blog
- **Read:** full text

## Summary

A skill is a directory containing a `SKILL.md` file plus optional reference files and scripts. `SKILL.md` starts with YAML frontmatter holding two required fields, `name` and `description`. The design goal is to give an agent domain knowledge without paying for it in context until it is needed. The article calls the loading scheme progressive disclosure and describes three levels.

Level 1: at start-up only the name and description of each installed skill are placed in the system prompt. This is enough for the model to judge relevance. Level 2: when the model decides a skill applies, it reads the body of `SKILL.md` with its normal file tool. Level 3: `SKILL.md` links to further files (for example a separate `forms.md` in the PDF skill) that are read only when that sub-topic comes up. Because loading is on demand, the total size of a skill is effectively unbounded.

Skills can also bundle scripts. The model runs a script as a tool without loading its source or its input data into context; the PDF skill ships a script that extracts form fields. The authors point out that deterministic code is more reliable and cheaper than token generation for operations like sorting or parsing.

Authoring advice: start from observed failures on representative tasks and add skills to fill those gaps; split a large `SKILL.md` into linked files; keep mutually exclusive topics in separate files; state whether a script is to be executed or read; pay most attention to the name and description because they drive triggering. Security: skills carry instructions and code, so install only from trusted sources and audit bundled files.

## Key points

- Three tiers: one-line metadata always loaded, body on trigger, linked files on demand.
- The description line is the retrieval key; its wording decides whether the skill is used.
- Scripts move work out of the context window entirely.
- Skills are built incrementally from observed agent failures.

## Relevance to JacKnife

(Our interpretation.)

- Jac documentation should be served this way: a short index of topics (one line each) in the prompt, with a `read_doc(topic)` tool for the body. A 9B model fine-tuned on Jac may need fewer topics in the index than a general model; measure which are actually used.
- The pattern is the same as fold/unfold: a short line plus an id. Use one consistent convention for both so the model learns a single habit.
- With a 16k budget the index itself must be small. The state machine can narrow it per phase (testing docs only in the unit-test phase).
- Loaded doc bodies should be foldable like any other tool result once the step that needed them is complete.

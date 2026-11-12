# Progressive Disclosure: Loading Documentation on Demand

A method note based on Anthropic's Agent Skills post [1].

- **Evidence:** D. Vendor engineering blog describing a product design; no measurements.
- **Numbers checked against the source:** yes, 2026-11-11, against the HTML page text. The post contains no numeric results.

## 1. Problem

An agent needs domain knowledge (how to fill a PDF form, a house style, a library's API), but loading all of it into every prompt wastes context and dilutes attention. The post describes how Anthropic packages such knowledge so that it costs almost nothing until it is needed. [1, introduction]

## 2. Method

A skill is a directory with a `SKILL.md` file and optional further files and scripts. `SKILL.md` starts with YAML frontmatter holding two required fields, `name` and `description`. [1, "The anatomy of a skill"]

Loading happens at three levels, which the post calls progressive disclosure [1, "The anatomy of a skill", "Skills and the context window"]:

| Level | What is in context | When |
|---|---|---|
| 1 | Name and description of every installed skill | Always, in the system prompt |
| 2 | Body of `SKILL.md` | When the model judges the skill relevant and reads the file with its Bash tool |
| 3+ | Linked files (in the PDF example, `reference.md` and `forms.md`) | Only when that sub-topic comes up |

Skills can also bundle scripts that the model runs without reading their source or their input into context. The PDF skill ships a script that extracts form fields. [1, "Skills and code execution"]

### Key decisions

1. **Metadata is the retrieval key.** The model decides whether to load a skill from its name and description alone, so those two fields need the most care. [1, "Developing and evaluating skills"]
2. **Use the agent's ordinary file tools.** There is no special loader; the model reads files as it would any other. [1, "Skills and the context window"]
3. **Move deterministic work into code.** Sorting or parsing by token generation is more expensive and less reliable than running a script. [1, "Skills and code execution"]
4. **Total size is effectively unbounded**, because only what is read enters the context. [1, "The anatomy of a skill"]

### Implementation details that generalise

- Build skills from observed failures on representative tasks, not from anticipated needs. [1, "Developing and evaluating skills"]
- Split a large `SKILL.md` into linked files, and keep mutually exclusive or rarely combined topics in separate files to save tokens. [1, "Developing and evaluating skills"]
- State whether a bundled script is to be run or read as reference. [1, "Developing and evaluating skills"]
- Watch real trajectories for unexpected paths or over-reliance on one file. [1, "Developing and evaluating skills"]
- Skills carry instructions and code, so install only from trusted sources and audit bundled files and network calls. [1, "Security considerations"]

## 3. Evidence

The post gives a worked example (the PDF skill) and a step-by-step trace of the context window, but no measured effect on accuracy, token use or how often skills are triggered correctly. [1, "Skills and the context window"]

## 4. Evidence boundaries

- **No data on triggering reliability.** Whether the model loads the right skill at the right time is not measured.
- **Frontier models only.** Level-2 loading depends on the model choosing to read a file from a one-line description, which is a judgement a small model may not make.
- **No guidance on how many skills** can sit in level 1 before the index itself costs too much.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Jac documentation fits this shape: a short topic index in the prompt, and a `read_doc(topic)` tool for the body. The phase can narrow the index (testing docs only in the unit-test phase).
- Our model loaded documentation on its own in only 3 of 12 tasks, so relying on level-2 self-triggering is risky. The harness should inject the relevant doc when a check fails with a known error class, and training trajectories should show doc loads.
- The index line plus id is the same pattern as a fold line plus id. One convention for both lets the model learn one habit.
- Loaded doc bodies should be foldable like any other tool result once the step that needed them is done.

## Reference

[1] Barry Zhang, Keith Lazuka, Mahesh Murag (Anthropic). *Equipping agents for the real world with Agent Skills.* Anthropic Engineering blog, 2025-10-16. <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>. Accessed 2026-11-11.

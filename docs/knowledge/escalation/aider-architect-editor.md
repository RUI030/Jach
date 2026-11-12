# Separating "Describe the Fix" from "Format the Edit" (Architect / Editor)

A method note based on Aider's architect/editor post [1] and its published benchmark data [2].

- **Evidence:** D. Vendor blog with a published results file but no controlled comparison: one benchmark, single runs, no variance, and one baseline run on a different test set.
- **Numbers checked against the source:** yes, 2026-11-11, against the post's Markdown source and `aider/website/_data/architect.yml` on the `main` branch (latest post commit `a42587b`, 2024-09-30).

## 1. Problem

Aider normally asks one model, in one response, to solve a coding problem and to emit the change in a strict edit format that Aider can apply. The post argues the model must "split its attention" between the two. The trigger was OpenAI's o1 models, which reasoned well but often produced badly formatted edits. [1, §Motivation, §Code reasoning and code editing]

## 2. Method

Two inference calls per task, possibly with two different models. [1, §Code reasoning and code editing]

1. **Architect:** describe how to solve the problem, in whatever form comes naturally.
2. **Editor:** given that description, produce well-formed edits to the existing files.

### Key decisions

1. **Free-form first, format second.** The architect is not constrained by the edit syntax at all.
2. **Choose each role by its needs.** A strong reasoner as architect; an editor chosen for cost, speed and edit skill. [1, §Code reasoning and code editing]
3. **The editor needs no deep reasoning**, so a cheaper model can fill it when the description is clear.

### Implementation details that generalise

- Edit format matters for the editor. "Whole" (rewrite the full file) gave the top score but is slow; "diff" is cheaper. [1, §Results]
- The split also works with one model in both roles, so it can be adopted without a second model. [1, §Results]

## 3. Evidence

Aider's code-editing benchmark, 133 test cases per run except where noted; the field reported is `pass_rate_2`. [2]

| Architect | Solo (edit format) | Best architect/editor pairing (editor, editor format) |
|---|---|---|
| o1-preview | 79.7% (diff) | 85.0% (DeepSeek or o1-mini, whole) |
| o1-preview | | 82.7% (Claude 3.5 Sonnet, diff) |
| Claude 3.5 Sonnet | 77.4% (diff) | 80.5% (itself, diff) |
| GPT-4o | 71.4% (diff) | 75.2% (itself, diff) |
| o1-mini | 61.1% (diff, **36 test cases**) | 71.4% (DeepSeek, whole) |
| GPT-4o-mini | 55.6% (whole) | 60.2% (itself, whole) |

[2]

- Self-pairing raised Sonnet by 3.1, GPT-4o by 3.8 and GPT-4o-mini by 4.6 points. [2]
- The post says DeepSeek as editor in diff format helped every architect except Sonnet. [1, §Results] In the data, Sonnet with DeepSeek scored 78.9% in both formats, 1.5 points above its solo score. [2]
- The post calls the top "whole"-format configurations "probably not practical" for interactive use because both steps are slow. [1, §Results]

## 4. Evidence boundaries

- The o1-mini solo baseline ran on 36 test cases, the pairings on 133. The 61.1 → 71.4 gain is not a like-for-like comparison.
- Single runs, no repeats. Gains of 3 to 5 points on 133 cases are 4 to 7 tasks.
- The benchmark is single-task editing of small exercises, not a multi-step agent loop with tool calls.
- All models are large frontier models of 2024. Nothing shows that a 9B model can turn another model's prose into correct edits, or write a useful description itself.
- The feature was experimental at publication. [1]

## 5. What we take from it

Our interpretation, not the source's claims.

- This is an "admin rewrites the task" mode at the level of one edit: the admin writes a precise description of the fix (file, location, change) and the 9B model applies it. Most tokens stay on the small model.
- The admin's output should be written for an executor, not as a discussion. That also makes it reusable as training data in our tool-call format.
- A no-admin variant targets our syntax-error streaks: the small model first states the intended change in prose, then edits in a second call. The self-pairing gains suggest this, but they were measured on large models.
- For small Jac files, a whole-file rewrite tool may be more reliable than search/replace edits for our model, at higher token cost. Worth measuring, not assuming.

## Reference

[1] Aider project. *Separating code reasoning and editing.* Blog post, 26 September 2024. <https://aider.chat/2024/09/26/architect.html>. Source: <https://raw.githubusercontent.com/Aider-AI/aider/main/aider/website/_posts/2024-09-26-architect.md>. Accessed 2026-11-11.

[2] Aider project. Benchmark data for the post, `aider/website/_data/architect.yml`, `main` branch. <https://raw.githubusercontent.com/Aider-AI/aider/main/aider/website/_data/architect.yml>. Accessed 2026-11-11.

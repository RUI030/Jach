# Spec, Plan, Tasks: Templates That Constrain the Model at Each Stage

A method note based on GitHub Spec Kit's `spec-driven.md` [1].

- **Evidence:** C. A product's own method document. Reliable for what the templates and commands do; it contains no measurement that the method works better.
- **Numbers checked against the source:** yes, 2026-11-11, against the raw file on `main` (last commit to the file 3cfc81f, 2026-06-23). The only numbers are the article counts, gate thresholds, and unmeasured time estimates.

## 1. Problem

In ordinary development the code is the maintained artefact and specifications drift out of date. Spec-driven development inverts this: the specification is maintained and code is generated from it. The document's practical question is how to make an LLM produce specifications and plans that are complete, unambiguous and do not jump to implementation. [1, "The Power Inversion", "Template-Driven Quality"]

## 2. Method

Three commands run a fixed sequence, each reading the previous stage's files. [1, "Streamlining SDD with Commands"]

| Command | Reads | Writes |
|---|---|---|
| `/speckit.specify` | A short feature description | A numbered feature directory on a new branch, with `spec.md`: user stories and acceptance criteria |
| `/speckit.plan` | `spec.md`, the project constitution | `plan.md`, plus data-model, API contract, research and `quickstart.md` validation-scenario files |
| `/speckit.tasks` | `plan.md` and, if present, data model, contracts, research | `tasks.md`, with independent tasks marked `[P]` |

### Key decisions

The templates are treated as prompts that constrain the model. [1, "Template-Driven Quality"]

1. **What and why, never how.** The spec template forbids tech stack, APIs and code structure.
2. **Uncertainty is marked, not guessed.** Both templates require `[NEEDS CLARIFICATION: question]` for anything the prompt does not specify.
3. **Checklists act as unit tests for the document.** For example: no clarification markers remain, requirements are testable, success criteria are measurable.
4. **Phase gates before implementation.** The plan template checks, for example, at most three projects, no future-proofing, framework used directly, contracts and contract tests defined. A failed gate must be justified in a "Complexity Tracking" section.
5. **Detail goes to separate files** so the plan stays readable.
6. **Test-first file order.** Contracts, then tests (contract, integration, e2e, unit), then source to make them pass.
7. **No speculative features.** Every feature must trace to a user story with acceptance criteria.

### Implementation details that generalise

The "constitution" is a file of project principles in nine articles. [1, "The Nine Articles of Development"]

- Article III makes test-first mandatory: no implementation before unit tests are written, approved by the user, and seen to fail.
- Article IX prefers real databases and services over mocks, with contract tests before implementation.
- Articles IV to VI are left for each project to define; a `/speckit.analyze` command checks a project against its own constitution. [1, "Articles IV, V & VI"]
- Other articles cover library-first structure, a text-in text-out CLI per library, and limits on projects and abstraction layers.

## 3. Evidence

None measured. The document's worked example claims about 15 minutes with the commands, against an estimated 12 hours of manual documentation for the same feature [1, "Example: Building a Chat Feature"]. Neither figure comes from a measurement or a comparison of outcomes.

## 4. Evidence boundaries

- **Description, not evaluation.** No source here shows that specs produced this way lead to more correct code, fewer defects, or better results for any model size.
- **The checklists are self-review.** The model runs them on its own output; the document does not say anything enforces them outside the model.
- **Human in the loop throughout.** A person invokes each command and approves tests (Article III). An unattended small-model loop is a different setting.
- **Document size.** The full set (spec, plan, research, data model, contracts, quickstart, tasks) is written for a frontier model with a large context; nothing addresses a tight budget.
- **The document changes.** The constitution articles were edited as recently as June 2026; later readers should check the current file.

## 5. What we take from it

Our interpretation, not the document's claims.

- Understand and plan can each have one template-defined output file (requirements, then plan with tasks), with the harness checking the structure before allowing the next phase.
- An explicit "needs clarification" slot gives a small model a sanctioned alternative to inventing requirements; the harness can stop and ask when it is non-empty.
- Self-check lists are weak for a 9B model. As many items as possible should become harness checks: the file exists, every task has criteria, every criterion names a test.
- Test-first order fits the phase machine: write the task's test, see it fail, then implement.

## Reference

[1] GitHub. *Specification-Driven Development (SDD)*, `spec-driven.md` in the `github/spec-kit` repository, branch `main`, last changed in commit 3cfc81f (2026-06-23). <https://raw.githubusercontent.com/github/spec-kit/main/spec-driven.md>. Accessed 2026-11-11.

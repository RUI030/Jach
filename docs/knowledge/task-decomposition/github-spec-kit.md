# Spec-Driven Development (GitHub Spec Kit, `spec-driven.md`)

- **Source:** https://github.com/github/spec-kit/blob/main/spec-driven.md
- **Authors / org:** GitHub (spec-kit repository)
- **Date:** undated repository document (fetched 2026-11-11 from the `main` branch)
- **Type:** docs
- **Read:** full text

## Summary

The document sets out the method behind Spec Kit. Its premise is that the specification, not the code, is the maintained artefact, and code is generated from it. Three commands run a fixed sequence.

`/speckit.specify` turns a short feature description into `spec.md` in a numbered feature directory on its own branch. The spec contains user stories and acceptance criteria and deliberately excludes technology choices. `/speckit.plan` reads the spec, checks it against the project "constitution", and writes `plan.md` plus supporting files: `research.md`, `data-model.md`, a `contracts/` directory with interface definitions, and `quickstart.md` with the key validation scenarios. `/speckit.tasks` reads the plan and design files and produces `tasks.md`, an ordered task list in which tasks that can run independently are marked `[P]`.

The templates are treated as prompts that constrain the model. Notable constraints: the spec must say what and why, never how; ambiguities must be flagged with a `[NEEDS CLARIFICATION]` marker instead of guessed; each template ends with a checklist the model runs against its own output; the plan has "phase gates" (for example limits on the number of projects and on added abstraction) and any violation must be justified in a complexity-tracking section; long detail goes into separate files so the main document stays readable; and files are created in test-first order (contracts, then tests, then source).

The constitution is a file of fixed project principles in nine articles. It includes library-first structure, a CLI interface per library, mandatory test-first development (tests written and seen to fail before implementation), simplicity and anti-abstraction rules, and a preference for integration tests against real services over mocks.

The document makes productivity claims (minutes instead of hours for the document set) without measurements.

## Key points

- Fixed pipeline: specify, plan, tasks; each stage reads the previous stage's file.
- Requirements and implementation choices are kept in separate documents.
- Explicit uncertainty markers replace silent guessing.
- Self-check lists and phase gates are built into the templates.
- Tasks are derived from contracts and data model, ordered test-first, with parallel-safe tasks marked.

## Relevance to JacKnife

(Our interpretation.)

- The understand and plan states can each have one template-defined output file (requirements, then plan, then tasks). The harness validates the structure before allowing the transition.
- An explicit "needs clarification" slot is cheap to add and gives a small model a sanctioned alternative to inventing requirements; the harness can stop and ask the user when it is non-empty.
- Checklists a model runs on its own output are weak for a 9B model; convert as many items as possible into harness checks (file exists, each task has criteria, each criterion names a test).
- Test-first ordering fits the state machine: write the task's test, see it fail, then implement.
- The full Spec Kit document set is too large for a 16k budget; keep each artefact short and load only the current task plus the contract it touches.

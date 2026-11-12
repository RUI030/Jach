# Kiro Specs (requirements, design, tasks)

- **Source:** https://kiro.dev/docs/specs/ and https://kiro.dev/docs/specs/feature-specs/
- **Authors / org:** Kiro (AWS)
- **Date:** undated living documentation (fetched 2026-11-11)
- **Type:** docs
- **Read:** both pages in full; the linked pages on task execution details and bugfix specs were not read

## Summary

Kiro is an agentic IDE whose "spec" feature formalises feature work into three files produced in three phases, with a review point after each.

`requirements.md` holds user stories with acceptance criteria written in EARS (Easy Approach to Requirements Syntax). The pattern given is `WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`; the docs' example is a form submitted with invalid data, where the system shall show validation errors beside the relevant fields. The stated benefits are that each criterion is unambiguous, testable and traceable. `design.md` holds the technical approach: architecture, component and data-flow descriptions, sequence diagrams, error handling and testing strategy. `tasks.md` holds discrete, trackable implementation tasks.

There are workflow variants. Requirements-first goes requirements, design, tasks. Design-first starts from an architecture or pseudocode and derives requirements and tasks from it, for cases with strict non-functional constraints or an existing design. Quick Spec generates all three files without approval gates, for well-understood features. An "Analyze Requirements" action checks requirements for inconsistencies, ambiguities, conflicting constraints and gaps before design starts.

Bug fixes use a different first file, `bugfix.md`, which records current behaviour, expected behaviour, and behaviour that must remain unchanged, followed by root-cause analysis, a fix design, and validation that nothing else broke.

Tasks have live status (in progress, completed) and can be run one at a time or all together. When all are run, Kiro builds a dependency graph and groups independent tasks into waves; tasks in a wave run concurrently and waves run in sequence.

The pages describe the product and give no evaluation data. The exact structure of `tasks.md` and how tasks reference requirements were not on the pages read.

## Key points

- Three files, three phases, a human review gate between phases (skippable for simple work).
- Acceptance criteria use a fixed sentence pattern (EARS) so each is testable.
- A requirements analysis pass runs before design.
- Bug fixes get a separate template that records behaviour to preserve.
- Task dependencies are explicit, which allows wave-based execution.

## Relevance to JacKnife

(Our interpretation.)

- EARS gives a fixed, short format for acceptance criteria that a small model can produce reliably and that a harness can parse: one line per criterion, each mapped to at least one test.
- The bugfix template's "unchanged behaviour" field is worth copying into the debug state: it tells the model which existing tests must still pass.
- A "quick" path without the full three-document flow is needed for small requests; the state machine should allow skipping design when the plan has a single task.
- Explicit task dependencies let the harness pick the next runnable task on resume without asking the model.

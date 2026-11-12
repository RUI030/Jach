# Requirements in EARS Sentences, Then Design, Then Dependency-Ordered Tasks

A method note based on the Kiro specs documentation [1, 2, 3].

- **Evidence:** C. Official product documentation. Reliable for what the feature does; it contains no evaluation data.
- **Numbers checked against the source:** yes, 2026-11-11, against the raw HTML of the three pages. They contain no performance numbers.

## 1. Problem

Agentic IDEs often go straight from a chat request to code, leaving no record of what was meant to be built and no way to track progress. Kiro's "specs" formalise feature work and bug fixes into three files, produced in three phases, with tracked tasks at the end. [1, "What are specs?"]

## 2. Method

Every spec has three files. [1, "Core Structure", "Three-Phase Workflow"]

| File | Holds |
|---|---|
| `requirements.md` (or `bugfix.md`) | User stories with acceptance criteria, or a bug analysis |
| `design.md` | Architecture, components, sequence diagrams and data flow, error handling, testing strategy |
| `tasks.md` | Discrete, trackable implementation tasks with live status |

### Key decisions

1. **Acceptance criteria in EARS.** Each requirement follows `WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`. The docs' example: when a user submits a form with invalid data, the system shall show validation errors beside the relevant fields. The stated benefits are clarity, testability, traceability and completeness. [2, "Requirements with EARS Notation"]
2. **A review point after each phase.** The user reviews and comments on each document before the next is generated. [1, "Getting Started"]
3. **Two orders, plus a fast path.** Requirements-first (requirements, design, tasks) for behaviour-driven work; design-first (design, requirements, tasks) when there are strict non-functional constraints or an existing design. Quick Spec runs all three phases without approval gates after asking clarifying questions up front. [2, "Workflow Variants"]
4. **Analyse requirements before design.** An optional pass checks requirements for inconsistencies, ambiguities, conflicting constraints and gaps. [2, "Analyzing requirements before design"]
5. **Bug fixes record what must not change.** `bugfix.md` has three EARS-style sections [3, "Bugfix Analysis Phase"]:
   - current behaviour: WHEN condition THEN the system does the wrong thing;
   - expected behaviour: WHEN condition THEN the system SHALL do the right thing;
   - unchanged behaviour: WHEN condition THEN the system SHALL CONTINUE TO do what it does now.

### Implementation details that generalise

- **Bugfix design states three properties to test**: the current code shows the bug, the fixed code behaves correctly, and unchanged behaviour still holds. The generated tasks carry property-based tests for each. [3, "Design Phase", "Tasks Phase"]
- **Wave scheduling.** When all tasks are run, Kiro builds a dependency graph from `tasks.md` and groups tasks into waves. Wave 1 is every task with no dependencies; each later wave holds tasks whose dependencies the earlier waves satisfied. Tasks in a wave run concurrently; waves run in sequence. [1, "Running tasks in parallel"]
- Task status is shown as in progress or completed while tasks run. [1, "Task Execution"]

## 3. Evidence

None. The pages describe the product. The claim that parallel execution "cuts execution time significantly" for most feature specs [1, "Running tasks in parallel"] comes with no measurement.

## 4. Evidence boundaries

- **No evaluation.** Nothing shows that EARS criteria, phase gates or bugfix templates improve correctness, for any model.
- **The task format was not on these pages.** How `tasks.md` records dependencies, and how tasks link back to requirements, is not described in the pages read.
- **A human reviews each phase** in the default flow. Quick Spec removes the gates for well-understood features, which suggests the full flow is slow for small work.
- **Feature availability differs by surface.** Analyze Requirements is listed for IDE and CLI only, and property-based correctness checking for the IDE only. [1, capability table]
- **Living documentation.** The pages were last updated 4 August 2026 and 15 October 2026 and may change.

## 5. What we take from it

Our interpretation, not the documentation's claims.

- EARS is a short, fixed sentence format for acceptance criteria that a small model can learn to produce and a harness can parse: one line per criterion, each mapped to at least one test.
- The "unchanged behaviour" section belongs in our debug phase: it names the existing tests that must keep passing, which is exactly the regression check the harness should run after each fix.
- Explicit task dependencies let the harness pick the next runnable task on resume without asking the model.
- A quick path that skips design is needed when the plan has a single task.

## Reference

[1] Kiro. *Specs.* <https://kiro.dev/docs/specs/>. Page updated 15 Oct 2026. Accessed 2026-11-11.

[2] Kiro. *Feature Specs.* <https://kiro.dev/docs/specs/feature-specs/>. Page updated 4 Aug 2026. Accessed 2026-11-11.

[3] Kiro. *Bugfix Specs.* <https://kiro.dev/docs/specs/bugfix-specs/>. Page updated 4 Aug 2026. Accessed 2026-11-11.

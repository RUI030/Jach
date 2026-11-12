# 0002: Support both interactive and automatic use

- **Status:** Accepted, 2026-11-11
- **Layer:** 4 (flow control), 6 (observability)

## Context

The harness could be built for a person at a terminal, for unattended batch runs, or for both. Early use will be mostly interactive while the workflow is being tuned. Trajectory generation for the training set needs unattended runs.

## Decision

1. Both modes are supported from the start.
2. The user chooses how automatic a run is. It is a setting, not a separate product.
3. Interactive use is expected to dominate early on.

## Consequences

- **The core must not depend on a UI.** The state machine, tools and context assembly run headless; any terminal interface is a client of that core.
- **Human checkpoints are gates like any other.** A phase transition can require approval (interactive) or pass automatically (auto). The state machine is the same in both.
- **Questions to the user need an auto-mode answer.** Wherever the harness would ask a person, auto mode needs a defined fallback: a default, the admin model, or stopping.
- **One trajectory format serves both modes.** Human input, admin input and automatic gate results are all recorded as events of the same log.

## Still open

- The granularity of the setting: one switch, or per-gate approval choices.
- Whether the admin model stands in for the human in auto mode.

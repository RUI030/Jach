# JacKnife

A coding-agent harness built for a small (9B) model fine-tuned on [Jac](https://www.jac-lang.org/).

General-purpose harnesses assume a large model that can plan for itself, pick from dozens of tools and recover from its own mistakes. JacKnife assumes the opposite: the harness owns the workflow, the tool set is small and Jac-specific, and work is cut into tasks with clear scope, inputs, outputs and acceptance criteria so the model can resume from any point.

## Status

Design phase. No harness code yet. Decisions are being made one at a time and recorded under `docs/decisions/`.

## Documentation

- [docs/README.md](docs/README.md): index, and the list of open design decisions
- [docs/research/](docs/research/): surveys of the pi harness, existing Jac harnesses, the model, and the jac CLI
- `docs/decisions/`: one record per design decision (added as each is settled)
- `docs/ref/<vendor>/`: copies of official third-party docs we depend on

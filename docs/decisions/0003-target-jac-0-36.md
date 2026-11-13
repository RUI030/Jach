# 0003: The harness targets Jac 0.36

- **Status:** Accepted, 2026-11-11
- **Layer:** all

## Context

Three Jac versions are in play (see [research/model-status-2026-11-11.md](../research/model-status-2026-11-11.md) and [research/jac-cli-surface.md](../research/jac-cli-surface.md)):

| Version | Where it is used |
|---|---|
| 0.34.28 | The jacBuilder production sandbox, and therefore every existing harness trajectory |
| 0.36.1 | The pre-training and single-turn SFT data of v1.35; the binary installed on the development machine |
| 0.38.0 | The local source checkout |

The versions differ in ways that matter to a harness. 0.36 removed the `sv` / `cl` placement markers. From 0.37, `jac start` becomes `jac run --serve` and the endpoint exposure rules change. The most common failure in current evaluations (client calls return 405) is suspected to come from writing 0.36-style code for a 0.34 runtime.

## Decision

Jach targets Jac 0.36. The harness, the training trajectories and the evaluation tasks all run on the same 0.36 release; 0.36.1 is the working version.

## Consequences

- The model's pre-training and its run-time environment agree for the first time.
- Existing harness trajectories (0.34.28) cannot be reused as they are. Anything taken from them has to be regenerated or checked on 0.36.
- Jach does not run inside the jacBuilder production sandbox while that sandbox pins 0.34.x.
- Every rule the harness enforces (wiring, imports, async) must be established by experiment on 0.36.1, not carried over from 0.34 findings.
- The harness still reads version-dependent knowledge from the installed binary (`jac guide`, release notes) instead of hard-coding it, so a later move to another version changes data, not harness code.

## Still open

- When and how to move to a later version.

# Idea inbox

"Decision" refers to the numbered list in [../README.md](../README.md). "From" is who raised it: R (Rui) or C (Claude).

| ID | Date | Idea | From | Decision | Status |
|---|---|---|---|---|---|
| I-001 | 2026-11-11 | A concise, Jac-specific tool set that lets the model build an app, run tests and so on | R | 6 | new |
| I-002 | 2026-11-11 | Define our own SDLC workflow: understand, implementation plan, implementation, unit test, debugging, e2e test | R | 4 | new |
| I-003 | 2026-11-11 | Load information dynamically so the model always matches the installed Jac version | R | 8 | new |
| I-004 | 2026-11-11 | Hard context limit of 262,144 tokens | R | 3 | discussing |
| I-005 | 2026-11-11 | No compaction. Fold every execution into one summary; the model can unfold any message to get the full content of that turn | R | 7 | new |
| I-006 | 2026-11-11 | Split work into tasks, each with clear scope, defined inputs and outputs, and acceptance criteria, so the model can pick up in the middle | R | 5 | new |
| I-007 | 2026-11-11 | Start from pi and extend it, or build from scratch | R | 11 | new |
| I-008 | 2026-11-11 | The harness defines the trajectory dataset format; trajectories are generated once the design is settled | R | 12 | new |
| I-009 | 2026-11-11 | Hybrid: harness-owned state machine outside, model-led loop inside each task | C | 1 | decided: [0001](../decisions/0001-flow-control-hybrid-state-machine.md) |
| I-010 | 2026-11-11 | An "admin": a large model that comes in to rescue the small model | R | 1, 10a | decided in principle: [0001](../decisions/0001-flow-control-hybrid-state-machine.md); mechanism open |
| I-011 | 2026-11-11 | Support interactive and auto; more interactive early on; the user decides whether to run auto | R | 2 | decided: [0002](../decisions/0002-interactive-and-auto-modes.md) |
| I-012 | 2026-11-11 | Treat 262k as a hard ceiling and aim for a much smaller working context per task, inside the length the model was trained on | C | 3 | discussing; waiting for the model status report |
| I-013 | 2026-11-11 | Training on the larger-VRAM machine already reaches 64k context | R | 3 | discussing |
| I-014 | 2026-11-11 | Tiered admin: advise first, take over only if the small model fails again; the admin may also rewrite a badly cut task | C | 10a | discussing |
| I-015 | 2026-11-11 | The admin uses the same tools and prompt format as the small model, so its interventions are training data without conversion | C | 10a, 12 | discussing |
| I-016 | 2026-11-11 | Run `jac check` automatically after every write, as harness behaviour and not a model choice | C | 6 | new |
| I-017 | 2026-11-11 | When a check fails, attach the relevant section of the guide the diagnostic points to, so the model need not decide what to look up | C | 8 | new |
| I-018 | 2026-11-11 | Keep tool parameters flat strings; the Qwen XML call format needs no JSON escaping for file contents | C | 6 | new |
| I-019 | 2026-11-11 | Use `jac code map` to give the model the real project structure, against hallucinated file paths | C | 6, 8 | new |
| I-020 | 2026-11-11 | Run only the named test by default; a full `jac test` starts 32 workers | C | 6 | new |
| I-021 | 2026-11-11 | Use the built-in `jac browse` for e2e tests; Playwright may not be needed | C | 6 | new |
| I-022 | 2026-11-11 | The core runs headless; any terminal UI is a client of it | C | 2, 11 | new |

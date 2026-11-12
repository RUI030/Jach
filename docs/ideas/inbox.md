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
| I-023 | 2026-11-11 | Knowledge articles follow a problem → method (key decisions, reusable implementation details) → evidence → evidence boundaries layout, with section-level citations and an evidence grade | R, C | docs process | discussing; pilot written |
| I-024 | 2026-11-11 | The harness triggers the admin; do not wait for the small model to ask for help | C | 10a | new |
| I-025 | 2026-11-11 | Train only on the admin's part of a rescued trajectory; mask the small model's failed prefix | C | 10a, 12 | new |
| I-026 | 2026-11-11 | "Done" is decided by hard checks the model cannot influence (entry replaced, no error overlay, not blank, required text present, no 4xx) | model status report | 4, 5 | new |
| I-027 | 2026-11-11 | Scaffold from a template that already has one working client-to-server round trip, so the model edits wiring and never invents it | model status report | 4, 6 | new |
| I-028 | 2026-11-11 | Write-time checks beyond `jac check`: backend module imported by the entry, imports resolve, `await` only in async; each failure states the concrete fix | model status report | 6 | new |
| I-029 | 2026-11-11 | One small job per fresh session; the harness verifies and writes the handover note from facts, never from the model's own summary | model status report | 5, 7 | new |
| I-030 | 2026-11-11 | On a detected loop, end the session and restart with a factual note; a warning message alone is ignored half the time | model status report | 10 | new |
| I-031 | 2026-11-11 | Cap reasoning length per step; 1112 produced runaway reasoning that hit the output limit | model status report | 1, 10 | new |
| I-032 | 2026-11-11 | Pin one Jac version across training data, harness and evaluation | model status report | 13 | new |
| I-033 | 2026-11-11 | An evaluation ladder from "one button changes one backend value" upward, three or more runs per task, always with a fixed baseline | model status report | 14 | new |

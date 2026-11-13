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
| I-034 | 2026-11-11 | A map tool: for a folder or the whole project, show the dependency graph (which file imports what, resolved to the actual file and function), so the model looks things up and stops inventing imports | R | 6, 8 | discussing; probe done, see research/compiler-probe-0.36.1.md |
| I-035 | 2026-11-11 | Make use of Jac's function signatures, strict types and the AST in tool design | R | 6 | discussing; probe done, see research/compiler-probe-0.36.1.md |
| I-036 | 2026-11-11 | Keep the fresh-session handover even though the experiment shows little gain today: when one agent fails, the next must work out the current state and continue. The model has to run alone eventually, and training should bring back instruction following and debugging | R | 5, 12 | new |
| I-037 | 2026-11-11 | The minimum input is the user's requirement. From it the model plans which `jac create` to run, which files, their dependency graph, which functions and what each does | R | 4 | new |
| I-038 | 2026-11-11 | The implementation plan holds a draft dependency graph, the function list with each function's purpose, and how client and server components connect | R | 4, 5 | new |
| I-039 | 2026-11-11 | Phase order: requirement → implementation plan → implementation → `jac check` and unit tests → per-page tests → full e2e → hand back to the user | R | 4 | new |
| I-040 | 2026-11-11 | E2E feedback through screenshots; unsure whether Playwright MCP is the right vehicle or something simpler exists | R | 6 | new |
| I-041 | 2026-11-11 | Mid-project change requests: the model revises the implementation plan and finds the code that must change | R | 4, 5 | new |
| I-042 | 2026-11-11 | Write the plan as real declaration files (signatures in `.jac`, bodies later in `.impl.jac`), so `jac check` validates the plan, each body is one task, and the dependency graph is derived from code | C | 4, 5 | discussing; probe says workable if the harness adds a missing-impl check and an impl-type check |
| I-043 | 2026-11-11 | Build a working client-to-server round trip first and fill in features after, since wiring is the most common failure | C | 4 | discussing |
| I-044 | 2026-11-11 | The 9B model is loaded text-only, so screenshots cannot be its feedback; give it the accessibility snapshot, console errors and failed requests, and keep screenshots for the admin and the user | C | 6 | discussing |
| I-045 | 2026-11-11 | File-level editing is probably enough; the open question is how the model locates the exact code to change, and whether the editing method matters much | R | 6 | discussing |
| I-046 | 2026-11-11 | No general shell tool for the small model; each needed command is its own narrow tool or runs automatically | C | 6 | discussing |
| I-047 | 2026-11-11 | Start with whole-file write plus exact search-and-replace; measure the edit failure rate before adding anything; edit-by-name on `impl` blocks is the fallback if text matching fails too often | C | 6 | discussing |
| I-048 | 2026-11-11 | The project map reports three states for a name: exists, planned but not built, unknown. "Unknown" defaults to "you referenced it wrongly; these are available" | R, C | 6, 8 | discussing |
| I-049 | 2026-11-11 | Separate internal names from external packages in the map; an external name is never "not built yet" | C | 6 | discussing |
| I-050 | 2026-11-11 | New cross-file modules or public functions require amending the plan first, which is recorded and creates a task; private helpers in the same file need no amendment | C | 4, 5 | discussing |
| I-051 | 2026-11-11 | Thinking stays on for a thinking-trained checkpoint, with a hard reasoning budget and a low `max_tokens` | training-side answers | 15 | new |
| I-052 | 2026-11-11 | At the step limit the harness writes the summary itself and never asks the model for one | training-side answers | 10 | new |
| I-053 | 2026-11-11 | Loop detection covers every tool, compares full arguments and the outcome, lets a write, error, rewrite cycle through, and escalates instead of repeating a warning | training-side answers | 10 | new |
| I-054 | 2026-11-11 | The edit tool rejects a no-op (identical old and new) and, when the old text is not found, returns the nearest real lines | training-side answers | 6 | new |
| I-055 | 2026-11-11 | Keep the fixed prompt small so far more of each training record carries loss; only 7% does in the current production data | C | 3, 12 | discussing |
| I-056 | 2026-11-11 | Target Jac 0.36 | R | 13 | decided: [0003](../decisions/0003-target-jac-0-36.md) |
| I-057 | 2026-11-11 | Installing plugins and packages is its own step or task between the implementation plan and implementation: the model proposes what it will use, installs it, then implements. This behaviour is trainable | R | 4 | new |
| I-058 | 2026-11-11 | The model must edit or create the right files; getting the file wrong is costly | R | 5, 6 | new |
| I-059 | 2026-11-11 | Difficulty ladder: a button on the home page that talks to the backend; then one simple page with a table or similar; then several pages. No elaborate layouts for now | R | 14 | new |
| I-060 | 2026-11-11 | The plan lists the files each task may create or edit; a write outside that list is rejected with the list | C | 5, 6 | discussing |
| I-061 | 2026-11-11 | The plan declares dependencies; the harness compares declared against installed and gates implementation on the match | C | 4 | discussing |
| I-062 | 2026-11-11 | Ship our own project template: single process, one working client-to-server call. The stock web-app template does not render on 0.36.1 | compiler probe | 4, 6 | new |
| I-063 | 2026-11-11 | Treat import warnings W1100, W1101 and W1102 as errors at write time | compiler probe | 6 | new |
| I-064 | 2026-11-11 | Wiring check at write time: every endpoint name a client module uses must be in the entry file's import list; confirm against `/openapi.json` | compiler probe | 6 | new |
| I-065 | 2026-11-11 | Catch `await` in non-async client code by syntax-checking the generated JavaScript | compiler probe | 6 | new |
| I-066 | 2026-11-11 | Keep the compiler loaded in a long-lived process ; saves start-up only (0.4 to 0.8 s). Check cost is about 1 s per 1,000 to 1,500 lines, so keep files small and check the edited file only | compiler probe | 6, 11 | new |
| I-067 | 2026-11-11 | On a parse error show only the first E0xxx and drop the cascade | compiler probe | 6 | new |
| I-068 | 2026-11-11 | Readiness means `/static/client.js` returns 200; `/healthz` stays 200 when every page is 503 | compiler probe | 6 | new |
| I-069 | 2026-11-11 | Feed the model the server log's source-mapped client errors as its main runtime signal | compiler probe | 6 | new |
| I-070 | 2026-11-12 | `lookup` tool: say what a name is (keyword, built-in, file, function, type, package export, unknown) | R | 6 | decided |
| I-071 | 2026-11-12 | When an error sits on a reserved word, add what that word means so the model can judge misuse. Probe: `node = "a"` gives an error that does not mention the keyword | R | 6, 8 | decided |
| I-072 | 2026-11-12 | Write the harness itself in Jac: work tree as nodes, flow as walkers, by-llm for model calls | R | 11 | discussing |
| I-073 | 2026-11-12 | Use walkers with `report` to extract views of a run (model context, training samples, token statistics) from a graph of turn nodes; record events to an append-only JSONL file by hand. Probe on 0.36.1: `report` values come back in `.reports`, are also printed to stdout under `jac run`; the graph persists between runs; walking 5,000 turns took 2.7 s | R | 12, 11 | discussing |
| I-074 | 2026-11-12 | `lookup` answers with an IDE-style hover card: full structure of a function, obj or node, the types it refers to, where it is used. Probe: `jac code symbol --text` and `jac code slice` give part of it | R | 6 | decided |
| I-075 | 2026-11-12 | The admin is a large model called through an API (a Codex or Claude Opus class model), not a locally hosted one | R | 10a | decided |

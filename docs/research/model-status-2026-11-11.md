# Model status: v1.35 baseline versus the 1112 adapter

Condensed from the report "JacLLM 現況報告：v1.35 基準 vs 1112 adapter" written by the training-side session on 2026-11-11 (<https://claude.ai/artifact/9orDoBYAVFiCsuwuWx3nTo>). All numbers are from that report. Each task was run once per model, so a difference of one or two tasks is noise.

## Headline

Judged by whether the app works in a real browser, both models score **0 of 13**. Fine-tuning on harness trajectories changed how the model behaves during a run but not whether the app works at the end.

## Setup

| Item | Value |
|---|---|
| v1.35 (baseline) | CPT + SFT on Jac 0.36.1 code. No tool trajectories. |
| 1112 (latest finished) | Rank-64 adapter on v1.35. 625 harness trajectories: production traces, replays of 14 reference UI apps, three sets of synthetic fix data. Validation loss 0.613. |
| Also tried | prod-only, and 1111 (UI trajectories, r16). Both 0 of 13. |
| Harness | JacHammer / jacBuilder. The platform scaffolds the project; the model has 27 tools. Projects run on **Jac 0.34.28**. |
| Context | 65,536 tokens. Compaction at 60% (about 39k). The first call is already 17k (system prompt plus tool schemas). |
| Sampling | llama-server, temperature 0.6, top-p 0.95, top-k 20, `max_tokens` 32,000, about 100 steps per task. |
| Tasks | 13: eight full-stack apps (todo, kanban, expenses, poll and others) and five UI pages. |

Two verdicts exist and they disagree:

- **Harness verdict:** did the last `browser_validate` report a pass with no writes after it. The template welcome page and a blank page both pass.
- **Browser e2e:** a Playwright script per task (open, fill, click, reload and check the data persisted). This is the verdict used here.

## Behaviour: v1.35 versus 1112

| Metric | v1.35 (13 tasks) | 1112 (12 tasks for step stats, 13 for browser) |
|---|---|---|
| Browser e2e pass | 0 / 13 | 0 / 13 |
| Where it stopped | Server down 3, page error 4, still template 6 | Server down 2, page error or blank 5, still template 6 |
| Harness said PASS | 11 / 13 | 8 / 13 |
| Hit the ~100-step limit | 10 / 13 | 6 / 12 |
| Tasks with LOOP DETECTED (messages) | 12 / 13 (240) | 9 / 12 (68) |
| Same call 50+ times in a row | 5 tasks | 2 tasks |
| Reasoning text before calls | None | Present; over 20,000 characters of runaway reasoning in 4 tasks |
| Truncated at the output limit | 3 tasks | 5 tasks |
| Rewrote the entry `main.jac` | 4 / 13 | 5 / 12 |
| `main.jac` imports the backend module | 0 | 0 |
| Installed shadcn components | 4 / 13 | 9 / 12 |
| Called `browser_validate` itself | 1 / 13 | 4 / 12 |
| Loaded a skill document | 6 tasks, 68 loads (two tasks: 27 and 29 repeats) | 3 tasks, 5 loads |
| Writes (write + edit) | 242 + 310 | 64 + 65 |

v1.35 stalls in extreme ways: one file rewritten 88 times; 82 edits in a row; 95 of 101 steps spent running commands with no file written.

### What 1112 can do

- Tool-call format is mostly correct. It lists and reads the template first. 8 of 12 tasks call the planning tool.
- It writes Jac of the right shape: nodes, walkers or `def:pub` functions on the server, stateful components on the client. About half the tasks end with a file that passes the syntax check.
- Given a fresh session and a factual handover note, it continues the work and does not start over.

### What neither model can do

- Finish any task.
- Wire client to server: no run ever imported the backend module in `main.jac`, so every client call returned 405.
- Recover from an error: in 6 of 12 tasks one unfixed syntax error lasted to the end.
- Use only things that exist: imports of modules, icons and functions that do not exist are common.
- Obey a harness warning: 6 of 12 tasks kept repeating after LOOP DETECTED.
- Look things up: the wiring rule is in a skill document, but only 3 of 12 tasks loaded any skill.
- Judge its own completion: it declares done on a template or blank page.

A per-task review of 1112 (by Opus against a fixed rubric): of 101 required features, 3 done, 9 partial, 57 written but blocked by another error, 32 not written.

## Where it fails

| Error (1112, 12 tasks) | Tasks | Effect | Detectable by code |
|---|---|---|---|
| Backend module not loaded (`main.jac` lacks the import) | 9 | Every backend call returns 405 | Yes: compare imports |
| Parse error left in place (unclosed tag, extra bracket) | 6 | Server does not start | Already reported; the model cannot fix it |
| `await` / `async` misuse | 6 | Invalid JS; the whole page dies | Yes; the current checker lets it through |
| Entry not replaced; page is still the template | 5 | Looks fine, nothing was built | Yes |
| Import of a module or name that does not exist | 4+ | Page fails to load | Yes: resolve imports at write time |
| Keeps repeating after LOOP DETECTED | 6 | Step budget exhausted | Yes: the harness can abort |
| Reasoning runs to the output limit | 5 | No action that step | Yes: cap reasoning length |

### Handover experiment

For each of 13 tasks, two more fresh sessions were run on the half-built project, each recorded in git.

- Final state: own page opens 2, page runs but backend 405 1, page error or blank 8, server down 2. Pass 0.
- "Still the template" fell from 6 to 0. The handover note got the model writing, but all six then broke.
- Only 2 tasks clearly advanced, fixing one error per session and exposing the next. Four tasks were in an identical state after sessions 2 and 3.
- Errors over the first 17 sessions: non-existent import 8, blank page 2, server down 2, wrong content 2, undefined name 1, `await` 1, 405 1.

## Process problems found

| Problem | What happened |
|---|---|
| The harness PASS is not trustworthy | 11/13 and 8/13 reported; the truth was 0. |
| Tasks too hard | All four model versions score 0, so the suite cannot rank them. |
| Training and run-time versions differ | Training code is Jac 0.36 (no `sv`/`cl` markers); the harness runs 0.34.28. On 0.34 a plain import compiles but the backend module is not loaded. |
| The checker disagrees with run time | `jac check` passes `await` in a non-async function, which kills the page, and reports type issues that do not affect execution. |
| Knowledge must be fetched | The wiring rule sits in a skill the model rarely loads. |
| Data bugs found late | 42 records had a working directory that did not match their tool-call paths. Of 2,082 training replies, only 10 were "saw a syntax error, then fixed it". One check bug let zero new records into training unnoticed. |
| Fixed overhead eats the context | 17k at the first call and compaction near 39k leave about 22k of working space. Compaction drops the contents of files written earlier. |
| One run per task | At temperature 0.6 a single run is noisy, and a full round takes over 10 hours on one GPU. |

## The report's recommendations

The report marks these as opinion, untested, ordered by expected benefit.

1. Start from a template that already has one working client-to-server round trip.
2. Block mechanically detectable errors at write time, with a concrete fix ("change line N to X").
3. Decide "done" by hard checks: entry is not the template, no error overlay, not blank, required text present, no 4xx from the backend.
4. One small job per session; the harness verifies, then opens the next. The handover note is generated by the harness from facts, not written by the model.
5. On a detected loop, end the session and restart; a message alone is ignored half the time. Restarting fixes "stuck" but not "cannot write it", so pair it with item 2.
6. Cut fixed overhead: about 11 of the 27 tools are needed; attach the relevant rules automatically; cap reasoning length.
7. Align versions: move the harness to 0.36, or rewrite the training data for 0.34.
8. An evaluation ladder (small, recombined, large), at least three runs per task, always alongside a fixed baseline.

## In progress and limits

- **1113 (training):** the 625 records plus full trajectories of about 15 single-page apps (a counter button, add a row, a checkbox, a toggle, a calculator), each verified in a browser. It targets wiring. Evaluated on 14 small tasks plus the original 13.
- The untuned base model has never been run in this harness, so it is unknown how much of the looping and hallucination comes from fine-tuning.
- Feature-completion and error classification were reviewed by hand only for 1112.

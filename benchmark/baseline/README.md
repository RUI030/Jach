# Baseline scripts

`run.sh` runs one task with the pi harness and gates it, `run_all.sh` runs every task of one arm (or the ids in
`TASKS`), and `collect.py` summarizes the results. Read
[docs/handoff/2026-11-19-baseline.md](../../docs/handoff/2026-11-19-baseline.md) for the experiment and how to run it.

| File | What |
|---|---|
| `run.sh <any\|jac> <task> <round>` | One run: copies the arm's scaffold, writes the prompt (task goal, plus the `{STACK}` paragraph for `any`), runs pi, then the gate |
| `run_all.sh <any\|jac> [rounds]` | Every task, easiest first; `TASKS="id id ..."` runs only those ids. Runs that already have a `gate.json` are skipped |
| `scaffold_any.sh <dir>` | Builds the `any` arm's starting project once: the Base scaffold of [`benchmark/fullstack-ab`](../fullstack-ab/README.md) (React, Vite, TypeScript, shadcn/ui + FastAPI with a virtualenv) and a `start.sh` that serves the page and the API on `$PORT` |
| `watch.py` | Stops a pi session that is stuck (a hung tool call, 5 minutes of silence, a repeated tool call, a thinking loop); `run.sh` then starts a fresh session on the same folder, at most 3 inside the run's 30 minutes |
| `collect.py <out root>` | `runs.json` (one row per run) and `summary.md` |
| `skills/` | The 40 Jac skill files given to the `jac` arm (exported from jac 0.36.1) |

Both arms start from a created, installed project, so a failure reflects the features the model built, not setup. The
browser actions and the gate (`jach/core/gate.jac`) are the same for both arms.

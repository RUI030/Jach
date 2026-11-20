# Full-stack A/B: one app spec, two stacks

A manual A/B test of building one real app from a spec: the same spec, filled in for two arms that differ in stack
(and, by default, model), each started from a fresh, installed scaffold. It is independent of the Jach harness and
needs only the agent you test with (pi or opencode), Node, Python 3 and jac.

Moved here on 2026-11-20 from a local folder (`JacLLM/AB`) as a reference for building the baseline: it shows how
to give each arm a proper starting project.

## Arms

| Arm | Stack | Starting project | Default model (`init.sh`) |
|---|---|---|---|
| `Base` | React (Vite, TypeScript) + FastAPI | `shadcn init -t vite` with 54 shadcn/ui components, `backend/` with a hello-world FastAPI app and a virtualenv | `unsloth/ornith-ai/Ornith-1.5-9B-GGUF:Q8_0` (untrained) |
| `JacLLM` | Jac | `jac create --use jac-shadcn` with the same 54 components | `unsloth/JacLLM-SFT-Ornith-9B-v1.3A_GGUF:Q8_0` (trained) |

For an untrained-vs-untrained run, set both to the same base model:

```bash
MODEL_JacLLM=unsloth/ornith-ai/Ornith-1.5-9B-GGUF:Q8_0 ./init.sh PaperJac
```

The model id only goes into each workspace's `opencode.json`; with pi you pick the model on the command line.

## Layout

| Path | What |
|---|---|
| `init.sh <SPEC> [APP]` | Makes `Impl/<arm>/<APP>/` for both arms: scaffold, seed data, `SPEC.md`, one git commit `scaffold` |
| `spec/<SPEC>/spec.md` | Level-1 requirement with `{APP}` and `{STACK}` filled per arm into `SPEC.md` |
| `spec/<SPEC>/spec2.md` | Level-2 follow-up message, sent in a new session after level 1 passes its first checks |
| `spec/<SPEC>/acceptance.md` | Tester-only checklist with expected answers and the session rules (budgets, what the tester may say). Never copied into a workspace |
| `spec/<SPEC>/*` (other files) | Seed data copied into every workspace (`papers.json` for PaperJac) |
| `Impl/` | Generated workspaces; git-ignored |

## Running one spec

1. `./init.sh PaperJac` (from this folder). An existing workspace is skipped, so delete it to start over.
2. Serve the model(s), then start the agent in `Impl/<arm>/PaperJac/` with MCP and skills off, as `acceptance.md` says.
3. Send `SPEC.md` unchanged as the first message. Follow the session rules in `acceptance.md`, then run its checks.
4. `git diff scaffold` in the workspace shows everything the model wrote.

## Adding a spec

Make `spec/<NAME>/spec.md` (use `{APP}` and `{STACK}`), optional `spec2.md`, `acceptance.md`, and any seed files.
Keep the requirement stack-neutral: `{STACK}` is the only place the arms differ.

Only `PaperJac` exists so far. Grading is manual (a person runs the checklist); for automated browser grading of small
apps, see `benchmark/baseline/` and the task specs in `jach/tasks/`.

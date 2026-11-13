# Jac spike: work tree, session walker, real model call

`spike.jac` (about 90 lines) builds root -> Project -> Feature -> Task -> Step, spawns one `Session` walker on the task, and calls a local `llama-server` at port 8791. Run on jac 0.36.1 on 2026-11-12 with JacLLM v1.35 Q4_K_M.

```
llama-server -m <model.gguf> --jinja -c 16384 -ngl 99 --port 8791
jac run spike.jac
```

Results are in [docs/decisions/0011-build-from-scratch-in-jac.md](../../docs/decisions/0011-build-from-scratch-in-jac.md).

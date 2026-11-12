# Compiler probe scripts

Throwaway scripts written while testing what the Jac 0.36.1 compiler can report. They are evidence for [docs/research/compiler-probe-0.36.1.md](../../docs/research/compiler-probe-0.36.1.md), not harness code.

| Script | Run | Prints |
|---|---|---|
| `imports.jac` | `jac run imports.jac <project-dir>` | Each import, the file it resolves to, and whether each imported name exists |
| `decls.jac` | `jac run decls.jac <file.jac>` | A declaration-only view: signatures, typed fields, docstrings; marks declarations with no body |
| `warm.jac` | `jac run warm.jac` | Time per re-check when the compiler stays loaded |
| `warm2.jac` | `jac run warm2.jac` | Same, with an on-disk edit to a dependency between runs |
| `lsp_probe.py` | `python3 lsp_probe.py` | Time from a change to diagnostics through `jac lsp` |

Paths inside the scripts point at the scratch projects they were written against and need editing before reuse.

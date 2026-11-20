# Jach project template

Every run starts from `jac create project --use jac-shadcn` (the installed Jac's own scaffold: Tailwind theme,
`components/ui/` with `Button` and `Card`, `lib/utils.jac`), with `AGENTS.md` removed and the three files here copied on top:
one page, one button, one server call. Verified on jac 0.36.1 on 2026-11-19: `jac check` is clean and clicking Ping in
`jac browse` shows `pong`.

| File | Role |
|---|---|
| `main.jac` | Entry. Names every endpoint in its import list; imports the theme CSS. |
| `server.jac` | Endpoints |
| `frontend.jac` | Client UI, built from `components/ui` |

Notes for the harness:

- The stock `--kind web-app` scaffold is not used: its `[scale.microservices]` section makes `/` return 404 on 0.36.1.
- The description and data rules check only the files a task may write, so the scaffold's own files (no descriptions) pass.
- The page needs a moment after `open` before a click registers. `browse` must wait for the target element, and wait for the expected text with a time limit, not sleep a fixed time.
- The console always shows a 404 for `/favicon.ico`. The page-test gate ignores it.
- Style warnings (W3xxx, for example empty parentheses) are not shown to the model as errors.

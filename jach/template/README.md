# Jach project template

The starting point Setup copies for every app: one page, one button, one server call. Verified on jac 0.36.1 on 2026-11-12: `jac check` is clean, `/static/client.js` returns 200, `POST /function/ping` returns `pong`, and clicking the button in `jac browse` shows `pong`.

| File | Role |
|---|---|
| `jac.toml` | No `[scale.microservices]` section (the stock template has one and does not render on 0.36.1) |
| `main.jac` | Entry. Names every endpoint in its import list. |
| `server.jac` | Endpoints |
| `frontend.jac` | Client UI |

Notes for the harness:

- The page needs a moment after `open` before a click registers. `browse` must wait for the target element, and wait for the expected text with a time limit, not sleep a fixed time.
- The console always shows a 404 for `/favicon.ico`. The page-test gate ignores it.
- Style warnings (W3xxx, for example empty parentheses) are not shown to the model as errors.

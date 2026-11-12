# What the Jac 0.36.1 compiler gives a harness

Experiments run on the installed jac 0.36.1 on 2026-11-11. Every result below was observed by running the command unless marked "0.38, read in source". The scripts used are in [`prototypes/compiler-probe/`](../../prototypes/compiler-probe/).

## Summary

| Failure mode | Detectable mechanically on 0.36.1? | How |
|---|---|---|
| Import of a `.jac` module that does not exist | Yes | Warning W1100; or the import script (resolution falls back to `py`) |
| Import of a name a `.jac` module does not define | Yes | Warning W1101; or look the name up in the module's scope |
| Python package not installed | Yes | W1100 |
| npm package not installed | Yes | W1100; or look in `.jac/client/node_modules/<pkg>` |
| Made-up export from an npm package (for example an icon) | Mostly | W1102, reliable for typed packages only; certain in the start log ("is not exported by") |
| jac-shadcn component not installed | Yes | W1100; or check `components/ui/<name>.jac` exists |
| Client not wired to server (HTTP 405) | Yes | Compare endpoint names against the entry file's import lists; confirm with `/openapi.json` |
| `await` in a non-async function | Yes, but not by `jac check` | `jac tool ir es <file> \| node --check` |
| Parse error | Yes; location is poor for unclosed JSX | `jac check -p` (0.19 s); show the first E0xxx only |
| Declared, never implemented | **Not by jac** | Walk the AST for declarations whose body is empty |
| Impl parameter or return types differ from the declaration | **Not by jac** | Compare the two signatures |
| Runtime page error | Yes | Server log, with positions mapped back to `.jac` lines; or `jac browse` |

Two results were unexpected:

- **The stock `jac create -k web-app` template does not render on 0.36.1.** Its `[scale.microservices.routes]` section starts a gateway and subprocesses, and `/static/client.js` returns 503.
- **An endpoint exists only if its exact name is imported into the entry file.** Importing the module is not enough. The 405 wiring failure seen on 0.34.28 therefore also happens on 0.36.1.

## 1. Import graph

No CLI command reports "file X imports names A, B from module M, which resolves to file Y".

| Command | What it gives | What is missing |
|---|---|---|
| `jac code uses NAME` | Definition and use sites | Import lines are not counted as uses |
| `jac check . --placements` | Imports per file with server or client placement | Names and resolved file |
| `jac install --plan --json` | What `jac.toml` declares | Anything about source files |
| `jac tool ir sym FILE` | Symbol tree for every module in the hub | Import edges |

About 40 lines against the compiler API produce the graph in about 1.3 s (`imports.jac`): compile each file with type checking and no code generation, walk the `Import` nodes, resolve each path, and look each imported name up in the target module's scope.

```
main.jac:6  Message[ok], PostMessage[ok], ListMessages[ok]  from endpoints (jac) -> endpoints.jac
cases/c2_missing_name.jac:1  Message[ok], DeleteMessage[NOT-EXPORTED]  from endpoints (jac) -> endpoints.jac
cases/c1_missing_mod.jac:1  list_todos[?]  from ..services.todos (py) -> hi/services/todos (MISSING)
cases/c4_npm_not_in_toml.jac:1  motion[npm-NOT-INSTALLED]  from framer-motion (string) -> ...
```

A `.jac` module that cannot be found is silently treated as a Python import. That fallback is the detection signal.

0.38, read in source: `jac arch graph --format json|mermaid` writes the import wiring, but needs an `archwire.jac` file first.

## 2. Declaration-only view

`jac code map` lists nodes and walkers only. It omits functions and components, drops field defaults, shows abilities without their entry clause, and shows no `:pub` tag. Functions appear only through `jac code symbol NAME`, one name per call.

A 50-line AST walk (`decls.jac`) prints a full declaration view in about 1.1 s:

```
node Task {  # A todo item.
    has title: str;
    has done: bool = False;
}
walker:pub AddTask {  # Create a task under root.
    has title: str;
    can make with Root entry;
}
def:pub count_open( prefix : str = "" , limit : int = 10 ) -> int;  # Count open tasks whose title starts with prefix.
```

For a client module it also lists component state and handlers. A docstring must come before its declaration; one placed inside a body is a parse error.

## 3. Declarations as a checkable plan

Signatures in `x.jac`, bodies in `x.impl.jac`.

| Situation | What `jac check` does |
|---|---|
| Declarations with no impl | **Passes, exit 0, no message.** Calling the function at run time returns `None`. |
| A call passes wrong argument types to a declared function | Caught: E1053 at the call site. Works for walker fields too. |
| Impl has a different parameter count | Caught: E2011, with E2012 pointing at the declaration |
| Impl uses a different parameter name | Warning W2013 |
| Impl has a different parameter type or return type | **Not caught.** The body is checked against the declaration's types. |
| Impl for a name that was never declared | E2009, followed by about 40 knock-on errors |
| A declaration's signature is changed | Every stale call site and the impl are reported (E1050 missing parameter, E1053 wrong type, E1052 unknown named argument) |
| JSX props passed to a declared component | Checked: E1100 wrong type, E1102 missing prop |
| Walker ability declared with no impl | Passes |

A body-less component declaration in a file of its own was placed on the server and rendered nothing, with no console error.

Declaration files therefore work as a plan the compiler can check for internal consistency and for stale call sites after a change. The harness has to add two checks jac does not make: every declaration has an impl, and impl types match declaration types.

## 4. Hallucinated imports

All six cases are **warnings**; `jac check` exits 0 for each.

| Case | `jac check` | Later |
|---|---|---|
| `.jac` module that does not exist | W1100 Module not found | Bundle builds; browser shows `ReferenceError` |
| Name missing from a `.jac` module | W1101 Cannot import name | Start log: `"X" is not exported by ...`; page is 503 |
| Python package not installed | W1100 | `jac run`: No module named |
| npm package not installed | W1100 | Not run |
| Made-up lucide icon | W1102 typed as any | Start log: not exported; page is 503 |
| shadcn component not installed | W1100 | Not run |

- W1100 looks in `node_modules`, not `jac.toml`, so a transitive dependency counts as present.
- W1102 also fires for real names from untyped packages, so it is trustworthy only for typed packages such as react and lucide.

## 5. Wiring client to server

**Rule:** an endpoint is registered if and only if its exact name appears in an `import from M { ... }` list in the entry file, or the entry file has `include M;`.

With the microservice routes removed from the template (single process, ready in about 3.6 s):

| Entry file imports from `endpoints` | Registered | Result of a call |
|---|---|---|
| `{Message, PostMessage, ListMessages}` | Two walkers; not `count_messages` | POST `/function/count_messages` → 405 |
| `{..., count_messages}` | Adds the function | 200 |
| `{Message, PostMessage}` | One walker | POST `/walker/ListMessages` → 405 |
| Nothing, or `import endpoints;` | None | 405 |
| `include endpoints;` | All | 200 |

- `jac check` passes in every row.
- GET on any endpoint path returns 404. `/openapi.json` lists what is registered.
- The bundled guide `jac-fullstack-patterns` states the same rule.
- `/healthz` returns 200 even when every page is 503, so it is not a readiness check for the client. `/static/client.js` returning 200 is.

## 6. `await` in a non-async function

`jac check` does not flag it on either side. (A missing `await` is flagged: E1042.)

- Server: `jac run` fails with E5043.
- Client: the generated JavaScript is invalid. `jac tool ir es FILE | node --check` reports the syntax error. At `jac start` the log shows `JAC_CLIENT_999`, pointing at a line of compiled JS.

0.38, read in source: adds E2085 for this.

## 7. Parse-error locations

| Mistake | Reported at | Quality |
|---|---|---|
| Unclosed `<p>` on line 4 | End of file, seven errors | Far from the mistake |
| Extra `}}` on line 7 | Line 8 | One line late |
| Missing `;` on line 2 | Line 3 | One line late |
| Unterminated string | The string itself | Correct |

Parse errors are followed by spurious type errors. Only the first E0xxx is worth showing.

## 8. Browser feedback as text

`jac browse` works for `open`, `navigate`, `wait`, `fill`, `click`, `eval`, `snapshot`, `console`, `screenshot`.

- The accessibility snapshot of the template page is 685 characters, with `@eN` references on interactive elements.
- A runtime error shows up in the snapshot as the error-boundary heading and message.
- Failed requests are visible in `console`, including the 405 and the endpoint name.
- The page posts its errors to the server, and the **server log prints them with positions mapped back to `.jac` source** (`at ... (components/AwaitBad.jac:2:5)`). This is the most useful signal for a text-only model.
- When the bundle fails to build, the snapshot shows "503 Service Unavailable" and the console is empty; the reason is in the start log.

## 9. Speed

| Method | Time per check |
|---|---|
| `jac check .` cold, five-file web app | 0.85 to 0.87 s |
| `jac check -p` (parse only) | 0.19 s |
| In-process, first run | 416 ms |
| In-process, later runs, including after an edit on disk | 7 to 14 ms |
| `jac lsp`, change to diagnostics | 0.32 s (a fixed 0.3 s debounce) |

A long-lived process that holds the compiler loaded is the fastest option by far.

## 10. Coming in 0.38 (read in source, not run)

`jac arch graph`, E2085 for `await`, W6009 (a client binding of a server endpoint is async), `jac check -j` (parallel).

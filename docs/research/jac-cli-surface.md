# jac 0.36.1 CLI surface for a harness

Surveyed 2026-11-11. Behaviour was observed on the installed binary, not read from the source repo.

**Version note.** The installed binary is 0.36.1. The local source repo is at 0.38.0, which removed `jac ai` and `jac ninja` and added `jac guide --sections`, `--section` and `--nav`. The harness must not assume one version.

## `jac check`

- Accepts files or directories (`jac check .`).
- Flags: `--lint`, `--lint --fix`, `-p/--parse_only`, `-n/--nowarn`, `-d/--disable-error-code CODE...`, `-i/--ignore DIR...`.
- No JSON output.
- Diagnostics go to **stderr**; the summary goes to stdout.
- Exit code 1 if any error, 0 otherwise.
- About 0.4 to 0.6 s per small file; 0.87 s for a five-file web-app.

```
✖ Error: error[E1053]: Cannot assign Literal["two"] to parameter 'b' of type int
  --> bad.jac:8:21
    8 |     x: int = add(1, "two");
      |                     ^^^^^
  → run 'jac guide jac-types' for guidance
```

Every diagnostic ends with a pointer to the guide that explains it. Parse errors use E0xxx. Summary line: `==== 1 failed in 0.54s ====`.

## `jac test`

- Flags: `-t NAME` (one test), `-f PATTERN` (file names), `-x` (stop on first failure), `-m N` (max failures), `-d DIR`, `-v`.
- No JSON or JUnit output.
- Runs pytest with xdist inside the payload. A full run started 32 workers: 2 tests took 4.9 s wall and about 100 s of CPU. The same file with `-t` took 0.7 s.
- Failure output is a long traceback ending in `AssertionError: assertion failed at <path>:<line>` and `FAILED t.jac::fails`.
- Exit code 1 on any failure.

## `jac code`

`jac code [symbol|uses|map|walkers|slice|diag] [target] [--text] [--depth N]`. JSON by default, paths absolute.

| Action | Returns |
|---|---|
| `map [kind]` | Every archetype: name, kind (node, walker, obj, edge), file, line, signature, fields, abilities, base classes. `--text` gives one line each. |
| `symbol X` | Definitions and uses of X |
| `uses X` | References, each marked `def` or `use` |
| `walkers NodeType` | Walker entry points for a node type |
| `slice X --depth N` | X plus related symbols |
| `diag [file]` | `{error_count, warning_count, diagnostics:[{file,line,severity,message}]}` |

`diag` has **no error code and no column**, and exits 0 even with errors. `jac check` output is the only source of codes and columns.

## `jac guide`

- `jac guide <name>`, `--search Q`, `--json`, `--export DIR`.
- `--json` lists 130 entries `{name, description, group, kind}`: 40 skills and 90 docs.
- Guides ship inside the binary, so they always match the installed version.

| Content | ~Tokens |
|---|---|
| jac-core-cheatsheet | 3.4k |
| jac-types | 2.1k |
| jac-walker-patterns | 2.5k |
| jac-cl-components | 6.2k |
| All 40 skills | 94k |
| All docs | 670k |

Version and change information available at run time:

- `jac --version` → `jac 0.36.1  (Linux x86_64)`
- `jac guide community/release_notes/jaclang`: per-version notes, each with a `### Breaking Changes` section
- `jac guide community/breaking-changes`
- A scaffolded `jac.toml` pins `jac-version = "==0.36.1"`

## Running and serving

**`jac run [file]`:** `--entry NAME`, `-e/--diagnostics error|all|none`, `--no-cache`. `-s/--show` prints what would run without running it.

**`jac start [file]`:**

- Flags: `-p PORT` (default 8000), `-d/--dev` (hot reload), `-n/--no-client`, `--takeover`.
- Runs in the foreground; the harness must background it.
- Readiness: stdout prints `Server ready`; `GET /healthz` returns 200. A single-file service was ready in about 1 s.
- Routes: `/function/<name>` and `/walker/<name>`.
- Response envelope: `{"ok":true,"type":"response","data":{"result":...,"reports":[]},"error":null}`.
- A scaffolded web-app with `[scale.microservices.routes]` starts a gateway and subprocess services. It was not serving after 25 s in testing.

**Others:**

- `jac create [name] -k KIND`: kinds `cli`, `cli-native`, `native-binary`, `native-lib`, `service`, `service-mesh`, `py-package`, `js-package`, `web-app`, `web-static`, `desktop`, `mobile`. `-s` skips dependency install. Generates an `AGENTS.md`.
- `jac install [pkgs]`: `-n/--npm`, `-s/--shadcn`, `--plan --json`, `--dry-run`.
- `jac build -c`: whole-program check only.
- `jac clean`: `-d` data (default), `-c` cache, `-a` all, `-f` skip the confirmation prompt.
- `jac fmt paths`: `-c` check only (exit 1 if unformatted).
- `jac dot`: graph to DOT.

## Browser and endpoint testing

- **`jac browse`** (hidden from `--help`): headless browser over CDP. Actions `open`, `navigate`, `click`, `type`, `fill`, `press`, `get`, `eval`, `wait`, `scroll`, `console`, `snapshot`, `screenshot`, `state`, `sessions`, `close`. `snapshot` returns an accessibility tree with `@e1` refs. Uses system Chrome or Playwright's Chromium, without depending on Playwright.
- **`JacTestClient`** (`runtimelib/testing.jac`): in-process endpoint tests with no server. `from_file(...)`, `get/post/put`, `register_user`, `login`, `set_auth_token`. Responses have `.json()`, `.ok`, `.status_code`.
- Nothing makes `jac test` render client components.

## `jac mcp`

19 tools (`validate_jac`, `check_syntax`, `format_jac`, `lint_jac`, `run_jac`, `search_docs`, `explain_error`, `py_to_jac`, `jac_to_py`, `jac_to_js`, `get_ast`, `graph_visualize`, `execute_command` and others), 136 resources (`jac://guide/<skill>`, `jac://docs/...`, `jac://grammar/spec`) and 9 prompts. The `--mode lite|standard|full` flag currently changes nothing.

Most MCP tools take a code string, not a project path, so they suit snippet validation more than project work.

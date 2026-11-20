"""Compiler access (decision 0011: all compiler calls go through this module)."""
import re;
import os;
import keyword;
import shutil;
import tempfile;
import subprocess;

"""How to fix errors whose compiler message does not say (decision 0006, error note)."""
glob ERROR_NOTES: dict = {
    "E1032": "the value has no known type. Give its variable a type, like `has items: list[Item] = [];`, and import `Item`."
};

glob HARD_WARNINGS = ["W1100", "W1101", "W1102"];

"""The installed Jac version, read from `jac --version` at run time."""
def jac_version -> str {
    words = subprocess.run(["jac", "--version"], capture_output=True, text=True).stdout.split();
    return words[1] if len(words) > 1 else "unknown";
}

glob RESERVED: list = [];

"""Words the installed compiler will not take as a name, found by compiling one parameter per candidate word
and keeping the words whose line has an error. `candidates` are words from the installed guides; Python's keywords are added."""
def reserved_words(candidates: list[str]) -> list[str] {
    if RESERVED { return RESERVED; }
    words = sorted(set([w for w in (candidates + keyword.kwlist) if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", w)]));
    probe_dir = tempfile.mkdtemp(prefix="jach-words-");
    # One declaration per line, blank lines between, so each error points at one word.
    src = "\n\n".join([f"def probe_{i}({w}: int) -> int {{ return 0; }}" for (i, w) in enumerate(words)]) + "\n";
    with open(os.path.join(probe_dir, "probe.jac"), "w") as f { f.write(src); }
    env = dict(os.environ);
    env["NO_COLOR"] = "1";
    out = subprocess.run(["jac", "check", "probe.jac"], cwd=probe_dir, capture_output=True, text=True, timeout=300, env=env);
    # Errors only: every probe line also warns that its parameter is unused.
    bad_lines = set([int(m.group(1)) for m in re.finditer(r"error\[E\d+\][^\n]*\n\s*--> probe\.jac:(\d+):", out.stdout + out.stderr)]);
    shutil.rmtree(probe_dir, ignore_errors=True);
    RESERVED.extend([w for (i, w) in enumerate(words) if 2 * i + 1 in bad_lines]);
    return RESERVED;
}

"""Run `jac check` on a path inside the project. Returns the diagnostics that count as errors.
A hard warning counts only in `warn_in` when it is given: the scaffold's own files are not the model's to fix."""
def diagnostics(project_dir: str, target: str, warn_in: list[str] | None = None) -> list[dict] {
    env = dict(os.environ);
    env["NO_COLOR"] = "1";
    # One unbuffered stream keeps each diagnostic next to its guide pointer, which jac prints to stdout.
    env["PYTHONUNBUFFERED"] = "1";
    proc = subprocess.run(["jac", "check", target], cwd=project_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120, env=env);
    out = proc.stdout;
    found: list[dict] = [];
    lines = out.split("\n");
    for (i, line) in enumerate(lines) {
        m = re.search(r"(error|warning)\[([EW]\d+)\]: (.*)", line);
        if not m { continue; }
        level = m.group(1);
        code = m.group(2);
        path = "";
        lno = 0;
        if i + 1 < len(lines) {
            loc = re.search(r"--> (.*?):(\d+):(\d+)", lines[i + 1]);
            if loc {
                path = os.path.relpath(loc.group(1), project_dir) if os.path.isabs(loc.group(1)) else loc.group(1);
                lno = int(loc.group(2));
            }
        }
        if level == "warning" and (code not in HARD_WARNINGS or (warn_in is not None and path not in warn_in)) { continue; }
        # The compiler ends a diagnostic with the guide that explains it: `→ run 'jac guide NAME' for guidance`.
        guide = "";
        for nxt in lines[i + 1:i + 15] {
            if re.search(r"(error|warning)\[[EW]\d+\]", nxt) { break; }
            g = re.search(r"jac guide ([\w./-]+)", nxt);
            if g { guide = g.group(1); break; }
        }
        found.append({"code": code, "message": m.group(3).strip(), "path": path, "line": lno, "guide": guide});
    }
    return found;
}

"""The lines around an error, without line numbers; the reported line starts with `> `, the others with two spaces."""
def excerpt(project_dir: str, path: str, lno: int) -> str {
    full = os.path.join(project_dir, path);
    if not path or not os.path.isfile(full) or lno <= 0 { return ""; }
    src = open(full).read().split("\n");
    lo = max(1, lno - 2);
    hi = min(len(src), lno + 1);
    rows: list[str] = [];
    for n in range(lo, hi + 1) {
        mark = "> " if n == lno else "  ";
        rows.append(mark + src[n - 1]);
    }
    return "\n".join(rows);
}

"""First error only, as text for the model plus a record for the log."""
def first_error(project_dir: str, target: str, warn_in: list[str] | None = None) -> dict {
    found = diagnostics(project_dir, target, warn_in);
    if not found { return {"clean": True, "text": "check: clean", "code": "", "message": ""}; }
    e = found[0];
    text = f"check failed: {e['code']} {e['message']}\nin {e['path']}:\n" + excerpt(project_dir, e["path"], e["line"]);
    if e["code"] in ERROR_NOTES { text = text.strip() + "\nnote: " + ERROR_NOTES[e["code"]]; }
    if e["guide"] { text = text.strip() + f"\nThe guide `{e['guide']}` explains this; read it with guide(topic=\"{e['guide']}\")."; }
    return {"clean": False, "text": text.strip(), "code": e["code"], "message": e["message"][:120]};
}

"""Names imported per module in one file: {module: [names]} (text scan; to be replaced by the AST walk)."""
def imports_of(path: str) -> dict {
    found: dict = {};
    for m in re.finditer(r"import\s+from\s+([\w.]+)\s*\{([^}]*)\}", open(path).read()) {
        names = [n.strip().split(" as ")[0].strip() for n in m.group(2).split(",") if n.strip()];
        found.setdefault(m.group(1).lstrip("."), []).extend(names);
    }
    return found;
}

"""The entry file named in jac.toml (`entry-point`); main.jac if the project does not say."""
def entry_of(project_dir: str) -> str {
    path = os.path.join(project_dir, "jac.toml");
    if os.path.isfile(path) {
        m = re.search(r'^\s*entry-point\s*=\s*"([^"]+)"', open(path).read(), re.M);
        if m { return m.group(1); }
    }
    return "main.jac";
}

"""Project files, relative paths, skipping build output and hidden folders."""
def project_files(project_dir: str) -> list[str] {
    found: list[str] = [];
    for (base, dirs, files) in os.walk(project_dir) {
        dirs[:] = sorted([d for d in dirs if not d.startswith(".") and d not in ["node_modules", "dist", "build", "__pycache__"]]);
        for f in sorted(files) {
            if not f.startswith(".") { found.append(os.path.relpath(os.path.join(base, f), project_dir)); }
        }
    }
    return found;
}

"""What a Jac file declares at top level, with the description written above each declaration
(text scan; to be replaced by the AST walk). First line: the file's own description."""
def outline(path: str) -> str {
    src = open(path).read();
    head = re.match(r'\s*"""(.*?)"""', src, re.S);
    lines: list[str] = [head.group(1).strip().split("\n")[0] if head else "(no description)"];
    pat = r'^(?:"""((?:(?!""").)*)"""[ \t]*\n)?((?:async\s+)?(?:def|walker|node|edge|obj|enum|glob)(?::pub|:priv)?\s+\w+[^{;=\n]*)';
    for m in re.finditer(pat, src, re.S | re.M) {
        doc = m.group(1).strip().split("\n")[0] if m.group(1) else "(no description)";
        lines.append(f"    {m.group(2).strip()}  : {doc}");
    }
    return "\n".join(lines);
}

"""Description rule (decision 0016): every top-level declaration in the given files says what it does, without an input/output list."""
def descriptions(project_dir: str, files: list[str]) -> dict {
    pat = r'^(?:"""((?:(?!""").)*)"""[ \t]*\n)?((?:async\s+)?(?:def|walker):pub\s+(\w+)[^{;=\n]*)';
    for rel in files {
        if not rel.endswith(".jac") or not os.path.isfile(os.path.join(project_dir, rel)) { continue; }
        src = open(os.path.join(project_dir, rel)).read();
        problem = "";
        for m in re.finditer(pat, src, re.S | re.M) {
            if problem { break; }
            doc = (m.group(1) or "").strip();
            sig = m.group(2).strip();
            if "JsxElement" in sig { continue; }
            if not doc { problem = f"`{sig}` in {rel} has no description"; }
            elif re.search(r"\b(Args|Returns|Parameters|Params)\s*:", doc) { problem = f"the description of `{sig}` in {rel} lists inputs or outputs; remove them"; }
            elif re.sub(r"[\W_]", "", doc).lower() == re.sub(r"[\W_]", "", m.group(3)).lower() { problem = f"the description of `{sig}` in {rel} only repeats its name"; }
        }
        if problem {
            text = f"check failed: DESCRIPTION {problem}.\n" + 'Put one sentence above it saying what it does, like:\n"""Store a new task and return it."""';
            return {"clean": False, "text": text, "code": "DESCRIPTION", "message": problem[:120]};
        }
    }
    return {"clean": True, "text": "", "code": "", "message": ""};
}

"""The project's own Jac files: every Jac file except those `jac create` made (listed in `.jach-scaffold` when the run starts).
The description rule and hard warnings apply to these; the scaffold's files are not the model's code."""
def own_files(project_dir: str) -> list[str] {
    listed = os.path.join(project_dir, ".jach-scaffold");
    scaffold = open(listed).read().split("\n") if os.path.isfile(listed) else [];
    return [f for f in project_files(project_dir) if f.endswith(".jac") and f not in scaffold];
}

"""Wiring rule (compiler probe section 5): an endpoint the client imports must be named in the entry file's import list.
Reports every missing name at once, with the full import line to write for each module."""
def wiring(project_dir: str, entry_file: str = "") -> dict {
    if not entry_file { entry_file = entry_of(project_dir); }
    entry_imports = imports_of(os.path.join(project_dir, entry_file));
    missing: dict = {};
    for fname in sorted(os.listdir(project_dir)) {
        if not fname.endswith(".jac") or fname == entry_file or not os.path.isfile(os.path.join(project_dir, fname)) { continue; }
        for (mod, names) in imports_of(os.path.join(project_dir, fname)).items() {
            mod_file = os.path.join(project_dir, mod.replace(".", "/") + ".jac");
            if not os.path.isfile(mod_file) { continue; }
            src = open(mod_file).read();
            for name in names {
                # A client component (returns JsxElement) is not a server endpoint and needs no entry import.
                decl = re.search(r"(def|walker):pub\s+" + re.escape(name) + r"\b[^{;]*", src);
                is_endpoint = decl is not None and "JsxElement" not in decl.group(0);
                if is_endpoint and name not in entry_imports.get(mod, []) and name not in missing.get(mod, []) {
                    missing.setdefault(mod, []).append(name);
                }
            }
        }
    }
    if not missing { return {"clean": True, "text": "", "code": "", "message": "", "fix": ""}; }
    fixes = [f"import from {mod} {{ {', '.join(entry_imports.get(mod, []) + names)} }}" for (mod, names) in missing.items()];
    listed = ", ".join([f"`{n}`" for names in missing.values() for n in names]);
    fix = "\n".join(fixes);
    text = f"check failed: WIRING {entry_file} needs:\n{fix}";
    return {"clean": False, "text": text, "code": "WIRING", "message": f"{entry_file} does not import {listed}", "fix": fix};
}

"""Every top-level name the project's Jac files declare, with the file that declares it (text scan)."""
def declared_names(project_dir: str) -> dict {
    found: dict = {};
    pat = r"^(?:async\s+)?(?:def|walker|node|edge|obj|enum|glob)(?::pub|:priv)?\s+(\w+)";
    for rel in project_files(project_dir) {
        if not rel.endswith(".jac") or rel.endswith(".impl.jac") or rel.endswith(".test.jac") { continue; }
        for m in re.finditer(pat, open(os.path.join(project_dir, rel)).read(), re.M) {
            found.setdefault(m.group(1), rel);
        }
    }
    return found;
}

"""Functions among `names` that are declared without a body (`def f(...) -> T;`) and have no `impl f` anywhere."""
def missing_bodies(project_dir: str, names: list[str]) -> list[str] {
    bare: list[str] = [];
    impls: list[str] = [];
    for rel in project_files(project_dir) {
        if not rel.endswith(".jac") { continue; }
        src = open(os.path.join(project_dir, rel)).read();
        bare += [m.group(1) for m in re.finditer(r"^(?:async\s+)?def(?::pub|:priv)?\s+(\w+)[^{;]*;", src, re.M)];
        impls += [m.group(1) for m in re.finditer(r"^\s*impl\s+(\w+)", src, re.M)];
    }
    return [n for n in names if n in bare and n not in impls];
}

"""The `test "name" { ... }` blocks in the project's own Jac files: name, file, and the block's text (text scan)."""
def test_blocks(project_dir: str) -> list[dict] {
    found: list[dict] = [];
    for rel in own_files(project_dir) {
        src = open(os.path.join(project_dir, rel)).read();
        for m in re.finditer(r'^test\s+"([^"]+)"\s*\{(.*?)^\}', src, re.M | re.S) {
            found.append({"name": m.group(1), "file": rel, "body": m.group(2)});
        }
    }
    return found;
}

"""Server functions declared without a body: each `def:pub` that does not return JSX. Tests are written for these."""
def open_endpoints(project_dir: str) -> list[str] {
    names: list[str] = [];
    for rel in own_files(project_dir) {
        for m in re.finditer(r"^(?:async\s+)?def:pub\s+(\w+)[^{;]*;", open(os.path.join(project_dir, rel)).read(), re.M) {
            if "JsxElement" not in m.group(0) and m.group(1) not in names { names.append(m.group(1)); }
        }
    }
    return missing_bodies(project_dir, names);
}

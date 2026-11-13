"""Compiler access (decision 0011: all compiler calls go through this module)."""
import re;
import os;
import subprocess;

glob HARD_WARNINGS = ["W1100", "W1101", "W1102"];

"""Run `jac check` on a path inside the project. Returns the diagnostics that count as errors."""
def diagnostics(project_dir: str, target: str) -> list[dict] {
    env = dict(os.environ);
    env["NO_COLOR"] = "1";
    proc = subprocess.run(["jac", "check", target], cwd=project_dir, capture_output=True, text=True, timeout=120, env=env);
    out = proc.stdout + "\n" + proc.stderr;
    found: list[dict] = [];
    lines = out.split("\n");
    for (i, line) in enumerate(lines) {
        m = re.search(r"(error|warning)\[([EW]\d+)\]: (.*)", line);
        if not m { continue; }
        level = m.group(1);
        code = m.group(2);
        if level == "warning" and code not in HARD_WARNINGS { continue; }
        path = "";
        lno = 0;
        if i + 1 < len(lines) {
            loc = re.search(r"--> (.*?):(\d+):(\d+)", lines[i + 1]);
            if loc {
                path = os.path.relpath(loc.group(1), project_dir) if os.path.isabs(loc.group(1)) else loc.group(1);
                lno = int(loc.group(2));
            }
        }
        found.append({"code": code, "message": m.group(3).strip(), "path": path, "line": lno});
    }
    return found;
}

"""The lines around an error, with the reported line marked (decision 0006, line numbers)."""
def excerpt(project_dir: str, path: str, lno: int) -> str {
    full = os.path.join(project_dir, path);
    if not path or not os.path.isfile(full) or lno <= 0 { return ""; }
    src = open(full).read().split("\n");
    lo = max(1, lno - 2);
    hi = min(len(src), lno + 1);
    rows: list[str] = [];
    for n in range(lo, hi + 1) {
        mark = ">" if n == lno else " ";
        rows.append(f"{mark}{n}│ {src[n - 1]}");
    }
    return "\n".join(rows);
}

"""First error only, as text for the model plus a record for the log."""
def first_error(project_dir: str, target: str) -> dict {
    found = diagnostics(project_dir, target);
    if not found { return {"clean": True, "text": "check: clean", "code": "", "message": ""}; }
    e = found[0];
    text = f"check failed: {e['code']} {e['message']}\n{e['path']}:{e['line']}\n" + excerpt(project_dir, e["path"], e["line"]);
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

"""Wiring rule (compiler probe section 5): an endpoint the client imports must be named in the entry file's import list.
Reports every missing name at once, with the full import line to write for each module."""
def wiring(project_dir: str, entry_file: str = "main.jac") -> dict {
    entry_imports = imports_of(os.path.join(project_dir, entry_file));
    missing: dict = {};
    for fname in sorted(os.listdir(project_dir)) {
        if not fname.endswith(".jac") or fname == entry_file or not os.path.isfile(os.path.join(project_dir, fname)) { continue; }
        for (mod, names) in imports_of(os.path.join(project_dir, fname)).items() {
            mod_file = os.path.join(project_dir, mod.replace(".", "/") + ".jac");
            if not os.path.isfile(mod_file) { continue; }
            src = open(mod_file).read();
            for name in names {
                is_endpoint = re.search(r"(def|walker):pub\s+" + re.escape(name) + r"\b", src) is not None;
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
    text = f"check failed: WIRING the page calls {listed} but {entry_file} does not import them, so the calls would return 405.\n"
        + f"{entry_file} must have this line:\n{fix}";
    return {"clean": False, "text": text, "code": "WIRING", "message": f"{entry_file} does not import {listed}", "fix": fix};
}

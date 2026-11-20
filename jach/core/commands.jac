"""Jac commands the tools run for the model: tests and package installs (decisions 0006, 0008).
Each returns {ok, text}; the text is short and names only project files."""
import os;
import re;
import subprocess;
import shutil;
import time;
import from check { excerpt }

glob INSTALL_KINDS = ["python", "npm"];

"""Run a jac command in the project with plain, unbuffered, single-stream output."""
def jac_cmd(project_dir: str, args: list[str], timeout: int, extra_env: dict = {}) -> dict {
    env = {**os.environ, "NO_COLOR": "1", "PYTHONUNBUFFERED": "1", **extra_env};
    try {
        p = subprocess.run(["jac"] + args, cwd=project_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout, env=env);
        return {"code": p.returncode, "out": p.stdout};
    } except subprocess.TimeoutExpired {
        return {"code": -1, "out": f"timed out after {timeout} s"};
    }
}

"""The first failure of a pytest report: the project source line it stopped at and the `E` lines after it.
`run_dir` is where the tests ran; the excerpt is read from there."""
def first_failure(run_dir: str, out: str) -> str {
    base: str = os.path.realpath(run_dir) + os.sep;
    lines = out.split("\n");
    where = "";
    for (i, ln) in enumerate(lines) {
        m = re.match(r"\s*(\S+\.jac):(\d+) in ", ln);
        if m and os.path.realpath(m.group(1)).startswith(base) {
            rel = os.path.relpath(os.path.realpath(m.group(1)), base);
            where = f"in {rel}:\n" + excerpt(run_dir, rel, int(m.group(2)));
        }
        if ln.startswith("E ") {
            errs = [x[1:].strip() for x in lines[i:i + 8] if x.startswith("E ")];
            return (where + "\n" if where else "") + "\n".join([e for e in errs if e]) if errs else where;
        }
    }
    return where;
}

"""Run the project's tests on a fresh copy, so every run starts with no stored data (Jac keys stored data by directory).
Returns rows {test name: passed|failed|error|skipped}, the failure text of each failed test, and the summary line;
`ran` is False when no test ran (a test file did not compile, the name matched nothing, or there are no tests)."""
def run_suite(project_dir: str, path: str = "", name: str = "") -> dict {
    copy = f"{project_dir.rstrip(os.sep)}-tests-{time.time_ns()}";
    shutil.copytree(project_dir, copy, symlinks=True, ignore=shutil.ignore_patterns("node_modules", ".jac", "dist", "build"));
    args = ["test", path if path else ".", "-v"] + (["-t", name] if name else []);
    try {
        # One worker: a full run otherwise starts one per core for a handful of tests.
        r = jac_cmd(copy, args, 300, {"JAC_TEST_JOBS": "0"});
        out: str = str(r["out"]);
        rows: dict = {};
        for m in re.finditer(r"^\S+?::(.+?) (PASSED|FAILED|ERROR|SKIPPED)\s*\[", out, re.M) { rows[m.group(1)] = m.group(2).lower(); }
        # pytest prints one `____ name ____` section per failed test.
        fails: dict = {};
        parts = re.split(r"^_{3,} (.+?) _{3,}$", out.split("short test summary info")[0], flags=re.M);
        for i in range(1, len(parts) - 1, 2) { fails[parts[i]] = first_failure(copy, parts[i + 1]); }
        summary = re.findall(r"=+ (.*(?:passed|failed|error|deselected|no tests ran).*?) in [\d.]+s =+", out);
        errs = [ln.strip() for ln in out.split("\n") if re.search(r"error\[E\d+\]|Error:|ERROR", ln)][:5];
        return {"ran": bool(rows), "rows": rows, "fails": fails, "tail": summary[-1] if summary else "", "errors": errs, "timeout": r["code"] == -1};
    } finally {
        shutil.rmtree(copy, ignore_errors=True);
    }
}

"""Why a suite run ran no test, as one failure text."""
def not_ran_text(s: dict, what: str) -> str {
    if s["timeout"] { return "failed: the tests timed out after 300 s."; }
    if "deselected" in s["tail"] or "no tests ran" in s["tail"] or not s["tail"] {
        return f"failed: {what}. Tests are `test \"name\" {{ ... }}` blocks." + (f"\n{s['tail']}" if s["tail"] else "");
    }
    return "failed: the tests did not run.\n" + "\n".join(s["errors"]) + f"\n{s['tail']}";
}

"""The `test` tool: run the project's tests, or one test by name."""
def run_tests(project_dir: str, path: str, name: str) -> dict {
    s = run_suite(project_dir, path, name);
    if not s["ran"] { return {"ok": False, "text": not_ran_text(s, (f"no test named `{name}`" if name else "no tests found") + (f" in {path}" if path else ""))}; }
    text = "\n".join([f"{v}: {k}" for (k, v) in s["rows"].items()]) + f"\n{s['tail']}";
    bad = [k for (k, v) in s["rows"].items() if v != "passed"];
    if not bad { return {"ok": True, "text": text}; }
    return {"ok": False, "text": text + f"\n\nfirst failure ({bad[0]}):\n" + s["fails"].get(bad[0], "")};
}

"""The `install` tool: add packages to jac.toml and install them."""
def install(project_dir: str, packages: str, kind: str) -> dict {
    names = [p for p in re.split(r"[\s,]+", packages.strip()) if p];
    kind = kind.strip().lower() or "python";
    if not names { return {"ok": False, "text": "failed: name at least one package."}; }
    if kind not in INSTALL_KINDS { return {"ok": False, "text": f"failed: kind must be one of {', '.join(INSTALL_KINDS)}."}; }
    args = ["install"] + (["--npm"] if kind == "npm" else []) + names;
    r = jac_cmd(project_dir, args, 600);
    keep = [ln.strip() for ln in r["out"].split("\n") if ln.strip() and not ln.strip().startswith(("Downloading", "Collecting", "Using cached", "Requirement already"))];
    if r["code"] == 0 {
        return {"ok": True, "text": f"installed ({kind}): {', '.join(names)}; recorded in jac.toml\n" + "\n".join(keep[-6:])};
    }
    return {"ok": False, "text": f"failed: install of {', '.join(names)} ({kind}) did not succeed:\n" + "\n".join(keep[-10:])};
}

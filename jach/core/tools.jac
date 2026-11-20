"""Tools the small model can call (decision 0006). Each returns the text for the model and a record for the log."""
import os;
import re;
import difflib;
import from check { first_error, wiring, entry_of, descriptions, own_files, project_files, outline }
import from knowledge { guide_text, guide_search }
import from commands { run_tests, install }
import from browse { run_actions }

"""How calls in one reply run (they always run in order):
reads never stop the reply; a failed change stops it; a run call is always the last one run."""
glob READS = ["list", "read", "search", "guide", "guide_search"];
glob CHANGES = ["write", "edit", "install"];
glob RUNS = ["test", "browse", "submit"];
glob PLANS = ["add_task", "drop_task"];
"""The tools the model sees in each phase (decision 0006 section 4)."""
glob PHASE_TOOLS: dict = {
    "plan": ["list", "read", "search", "guide", "guide_search", "write", "edit", "add_task", "drop_task", "submit"],
    "tests": READS + ["write", "edit", "test", "submit"],
    "task": READS + CHANGES + RUNS
};
glob STEP_VERBS = ["open", "click", "fill", "press", "wait", "expect", "expect_not"];

def param(desc: str) -> dict { return {"type": "string", "description": desc}; }

"""One tool schema. A parameter whose description starts with "Optional" is not required."""
def tool(name: str, desc: str, props: dict) -> dict {
    need = [k for (k, v) in props.items() if not v["description"].startswith("Optional")];
    return {"type": "function", "function": {"name": name, "description": desc,
            "parameters": {"type": "object", "properties": props, "required": need}}};
}

glob PATH_DESC = "File path relative to the project root, as `list` shows it";
glob SEARCH_HITS = 30;

glob SCHEMAS: list[dict] = [
    tool("list", "Given nothing, return every file in the project; given a folder, only the files under it. Each Jac file comes with one line per top-level declaration and the description written above it.",
        {"path": param("Optional: a folder; empty lists the whole project")}),
    tool("read", "Given a file path, return the file's current text exactly as stored.",
        {"path": param(PATH_DESC)}),
    tool("write", "Given a file path and the complete new text, replace the whole file with that text, or create the file. Then run jac check on it and return `check: clean` or the first error. An existing file must be read first, so nothing in it is lost.",
        {"path": param(PATH_DESC), "content": param("The complete new text of the file")}),
    tool("edit", "Given a file path, a piece of its current text `old`, and `new`, replace `old` with `new`. `old` is found by exact text match and must occur exactly once. Then run jac check and return `check: clean` or the first error. If `old` is not found, return the closest lines in the file.",
        {"path": param(PATH_DESC), "old": param("Text copied exactly from the file"), "new": param("The text that replaces it")}),
    tool("search", "Given a piece of text, return every line of the project's files that contains it exactly, each with its file name. Given also a path, search only that file or folder.",
        {"text": param("The exact text to find"), "path": param("Optional: a file or folder to search in; empty searches the whole project")}),
    tool("guide", "Given a topic name, return that page of the Jac guide for the installed Jac version. Given also a section title, return only that section. A page too long to show whole comes back as its list of sections.",
        {"topic": param("A guide name from the list in the system prompt, such as jac-cl-components, or a doc name such as community/breaking-changes"), "section": param("Optional: a heading title, or part of one, inside the page")}),
    tool("guide_search", "Given a word or phrase, return the guide sections of the installed Jac version that contain it, with the first matching line of each. Use it when you do not know which guide covers something.",
        {"text": param("The word or phrase to find, such as a keyword, a function name or an error code")}),
    tool("install", "Given package names and their kind (python or npm), add them to jac.toml and install them. Return the installed packages, or the installer's error.",
        {"packages": param("Package names separated by spaces; a version may follow the name, such as `requests>=2.31`"), "kind": param("python or npm")}),
    tool("test", "Given nothing, run every test block in the project; given a test name, run only that test; given a path, run only the tests of that file. Each run starts with no stored data; the tests of one run share it, one at a time. Return passed or failed per test and, for the first failure, the line it stopped at and the assertion error.",
        {"name": param("Optional: the name of one test, as written in `test \"name\" { }`"), "path": param("Optional: a Jac file whose tests to run")}),
    tool("browse", "Given steps, one per line, start a fresh copy of the app with no stored data, run the steps in a headless browser, then stop it. Steps: `open /path`, `click <label>`, `fill <label> | <text>`, `press <key>`, `wait <seconds>`, `expect <text>`, `expect_not <text>`; a label is the visible text or placeholder of an element. Return each step with ok, or the first failed step with the page's text and any console error.",
        {"steps": param("The steps, one per line, such as `open /` then `click Like` then `expect Likes: 1`")}),
    tool("add_task", "Given an id, a title, a goal, the declared functions the task writes or changes, the earlier tasks it needs, and the browser actions it delivers, add the task to the plan. Return the task list and what the plan still lacks.",
        {"id": param("A short id, such as T01"), "title": param("A few words, such as Add an item"),
         "goal": param("One sentence saying what works when the task is done"),
         "implements": param("Optional: names of the declared functions this task writes or changes, separated by commas: those declared without a body, and existing ones it changes, such as the page component"),
         "depends_on": param("Optional: ids of tasks added earlier that must be done first, separated by commas"),
         "actions": param("Optional: names of the browser actions from the requirement this task makes pass, one per line")}),
    tool("drop_task", "Given a task id, remove the task from the plan. Return the task list and what the plan still lacks.",
        {"id": param("The id of the task to remove")}),
    tool("submit", "Given nothing, run the checks the card lists under `Done when`, in that order. Return `check: clean` and end the work when all pass, or the first failure.",
        {})
];

def result(status: str, target: str, text: str, code: str = "", message: str = "") -> dict {
    return {"status": status, "target": target, "text": text, "code": code, "message": message};
}

def safe_path(project_dir: str, path: str) -> str {
    full = os.path.realpath(os.path.join(project_dir, path));
    root_dir = os.path.realpath(project_dir);
    return full if (full == root_dir or full.startswith(root_dir + os.sep)) else "";
}

def after_change(project_dir: str, path: str, done: str) -> dict {
    chk = first_error(project_dir, path) if path.endswith(".jac") else {"clean": True, "text": "", "code": "", "message": ""};
    if chk["clean"] {
        w = wiring(project_dir);
        note = "" if w["clean"] else f"\ntodo: {entry_of(project_dir)} needs:\n{w['fix']}";
        return result("ok", path, f"{done}\ncheck: clean{note}");
    }
    return result("failed", path, f"{done}\n{chk['text']}", chk["code"], chk["message"]);
}

"""Every project line that contains `text`, as `file: line`, under `path` (a file or folder; empty is the whole project)."""
def search_text(project_dir: str, path: str, text: str) -> dict {
    if not text { return result("failed", path, "failed: give the text to find.", "no-text"); }
    under = path.strip().rstrip("/");
    hits: list[str] = [];
    total = 0;
    for rel in project_files(project_dir) {
        if under and rel != under and not rel.startswith(under + "/") { continue; }
        try { rows = open(os.path.join(project_dir, rel)).read().split("\n"); } except Exception { continue; }
        for ln in rows {
            if text in ln {
                total += 1;
                if len(hits) < SEARCH_HITS { hits.append(f"{rel}: {ln.strip()}"); }
            }
        }
    }
    if not hits { return result("ok", text[:60], f"no line contains `{text}`" + (f" in {under}." if under else ".")); }
    more = f"\n... {total - len(hits)} more; search a narrower path or longer text." if total > len(hits) else "";
    return result("ok", text[:60], "\n".join(hits) + more);
}

"""Project files under a folder; each Jac file with its outline."""
def list_files(project_dir: str, folder: str) -> dict {
    under = folder.strip().strip("/");
    files = [f for f in project_files(project_dir) if not under or f == under or f.startswith(under + "/")];
    if not files { return result("failed", folder, f"failed: no files under `{folder}`.", "not-found"); }
    rows = [f"{rel}: " + outline(os.path.join(project_dir, rel)) if rel.endswith(".jac") else rel for rel in files];
    return result("ok", under or ".", "\n".join([r.rstrip() for r in rows]));
}

"""The schemas of the named tools, in the order of SCHEMAS."""
def schemas_for(names: list[str]) -> list[dict] {
    return [s for s in SCHEMAS if s["function"]["name"] in names];
}

"""Browser steps from the model's text, one per line, as [verb, argument] or [fill, label, text]. Empty `error` means they parsed."""
def parse_steps(text: str) -> dict {
    steps: list[list[str]] = [];
    for ln in [x.strip() for x in text.strip().split("\n") if x.strip()] {
        verb = ln.split(" ")[0].strip().lower().rstrip(":");
        arg = ln[len(ln.split(" ")[0]):].strip();
        if verb not in STEP_VERBS { return {"steps": [], "error": f"`{ln}`: a step starts with one of {', '.join(STEP_VERBS)}"}; }
        if not arg { return {"steps": [], "error": f"`{ln}`: {verb} needs an argument"}; }
        if verb == "fill" {
            if "|" not in arg { return {"steps": [], "error": f"`{ln}`: write fill as `fill <label> | <text>`"}; }
            steps.append(["fill", arg.split("|")[0].strip(), arg.split("|", 1)[1].strip()]);
        } else { steps.append([verb, arg]); }
    }
    if not steps { return {"steps": [], "error": "no steps given"}; }
    if steps[0][0] != "open" { return {"steps": [], "error": "the first step must be `open /path`"}; }
    return {"steps": steps, "error": ""};
}

def run_tool(project_dir: str, name: str, args: dict, port: int = 8795) -> dict {
    if name not in READS + CHANGES + RUNS {
        return result("refused", name, f"refused: no tool `{name}`. Tools: {', '.join(READS + CHANGES + RUNS)}.", "no-such-tool");
    }
    if name == "submit" {
        mine = own_files(project_dir);
        chk = first_error(project_dir, ".", mine);
        if chk["clean"] { chk = wiring(project_dir); }
        if chk["clean"] { chk = descriptions(project_dir, mine); }
        if chk["clean"] { return result("ok", "step", "check: clean"); }
        return result("failed", "step", chk["text"], chk["code"], chk["message"]);
    }
    if name == "guide" {
        g = guide_text(str(args.get("topic", "")), str(args.get("section", "")));
        return result("ok" if g["ok"] else "failed", str(args.get("topic", "")), g["text"], "" if g["ok"] else "no-guide");
    }
    if name == "guide_search" {
        g = guide_search(str(args.get("text", "")));
        return result("ok" if g["ok"] else "failed", str(args.get("text", ""))[:60], g["text"], "" if g["ok"] else "no-match");
    }
    if name == "install" {
        r = install(project_dir, str(args.get("packages", "")), str(args.get("kind", "")));
        return result("ok" if r["ok"] else "failed", "jac.toml", r["text"], "" if r["ok"] else "install-failed", "" if r["ok"] else r["text"].split("\n")[0][:120]);
    }
    if name == "test" {
        tpath = str(args.get("path", "")).strip();
        if tpath and not (safe_path(project_dir, tpath) and os.path.isfile(os.path.join(project_dir, tpath))) {
            return result("failed", tpath, f"failed: no file `{tpath}`.", "not-found");
        }
        r = run_tests(project_dir, tpath, str(args.get("name", "")).strip());
        return result("ok" if r["ok"] else "failed", tpath or "tests", r["text"], "" if r["ok"] else "TEST", "" if r["ok"] else r["text"].split("\n")[0][:120]);
    }
    if name == "browse" {
        ps = parse_steps(str(args.get("steps", "")));
        if ps["error"] { return result("failed", "browser", f"failed: {ps['error']}.", "bad-steps", ps["error"][:120]); }
        r = run_actions(project_dir, port, [{"name": "browse", "steps": ps["steps"]}])[0];
        text = r["text"] if r["status"] == "ok" else f"failed: {r['message']}\n{r['text']}";
        return result("ok" if r["status"] == "ok" else "failed", "browser", text, "" if r["status"] == "ok" else "BROWSER", "" if r["status"] == "ok" else r["message"][:120]);
    }
    if name == "list" { return list_files(project_dir, str(args.get("path", ""))); }
    if name == "search" and not str(args.get("path", "")).strip() { return search_text(project_dir, "", str(args.get("text", ""))); }
    path = str(args.get("path", ""));
    full = safe_path(project_dir, path);
    if not path or not full {
        return result("refused", path, f"refused: `{path}` is outside the project.", "bad-path");
    }
    if name == "search" { return search_text(project_dir, path, str(args.get("text", ""))); }
    if name == "read" {
        if not os.path.isfile(full) {
            names = sorted([f for f in os.listdir(project_dir) if f.endswith(".jac") or f.endswith(".toml")]);
            return result("failed", path, f"failed: no file `{path}`. Files: {', '.join(names)}", "not-found");
        }
        return result("ok", path, open(full).read());
    }
    if name == "write" {
        content = str(args.get("content", ""));
        if os.path.isfile(full) and open(full).read() == content {
            return result("refused", path, f"refused: {path} already has this content.", "no-change");
        }
        with open(full, "w") as f { f.write(content); }
        return after_change(project_dir, path, f"wrote {path}");
    }
    # edit
    if not os.path.isfile(full) { return result("failed", path, f"failed: no file `{path}`.", "not-found"); }
    old = str(args.get("old", ""));
    new = str(args.get("new", ""));
    if old == new { return result("refused", path, "refused: `old` equals `new`.", "no-change"); }
    src = open(full).read();
    n = src.count(old) if old else 0;
    if n == 0 {
        first = old.strip().split("\n")[0] if old.strip() else "";
        close = difflib.get_close_matches(first, src.split("\n"), n=3, cutoff=0.5);
        hint = "\n".join(close) if close else "(nothing similar)";
        return result("failed", path, f"failed: `old` not found in {path}. Closest lines:\n{hint}\nCopy the text exactly.", "old-not-found");
    }
    if n > 1 { return result("failed", path, f"failed: `old` appears {n} times in {path}. Include more lines.", "old-not-unique"); }
    with open(full, "w") as f { f.write(src.replace(old, new)); }
    return after_change(project_dir, path, f"edited {path}");
}

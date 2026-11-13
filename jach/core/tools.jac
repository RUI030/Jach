"""Tools the small model can call (decision 0006). Each returns the text for the model and a record for the log."""
import os;
import re;
import difflib;
import from check { first_error, wiring, entry_of }

glob PREFIX = r"^\s*>?\d+│ ?";

glob SCHEMAS: list[dict] = [
    {"type": "function", "function": {"name": "read", "description": "Read a file. Lines are shown with a number prefix that is not part of the file.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]}}},
    {"type": "function", "function": {"name": "write", "description": "Create a file or replace its whole content. The file is checked afterwards.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}, "content": {"type": "string"}}, "required": ["path", "content"]}}},
    {"type": "function", "function": {"name": "edit", "description": "Replace one exact piece of text in a file. `old` must appear exactly once. The file is checked afterwards.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}, "old": {"type": "string"}, "new": {"type": "string"}}, "required": ["path", "old", "new"]}}},
    {"type": "function", "function": {"name": "submit", "description": "Say the current step is finished. The harness then runs the step's checks.",
        "parameters": {"type": "object", "properties": {}, "required": []}}}
];

def result(status: str, target: str, text: str, code: str = "", message: str = "") -> dict {
    return {"status": status, "target": target, "text": text, "code": code, "message": message};
}

def strip_prefix(text: str) -> str {
    return "\n".join([re.sub(PREFIX, "", ln) for ln in text.split("\n")]);
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
        note = "" if w["clean"] else f"\nstill to do: {entry_of(project_dir)} must have this line, or the page's calls return 405:\n{w['fix']}";
        return result("ok", path, f"{done}\ncheck: clean{note}");
    }
    return result("failed", path, f"{done}\n{chk['text']}", chk["code"], chk["message"]);
}

def run_tool(project_dir: str, writes: list[str], name: str, args: dict) -> dict {
    if name not in ["read", "write", "edit", "submit"] {
        return result("refused", name, f"refused: there is no tool named `{name}`. Tools: read, write, edit, submit.", "no-such-tool");
    }
    if name == "submit" {
        chk = first_error(project_dir, ".");
        if chk["clean"] { chk = wiring(project_dir); }
        if chk["clean"] { return result("ok", "step", "check: clean"); }
        return result("failed", "step", chk["text"], chk["code"], chk["message"]);
    }
    path = str(args.get("path", ""));
    full = safe_path(project_dir, path);
    if not path or not full {
        return result("refused", path, f"refused: `{path}` is not a path inside the project.", "bad-path");
    }
    if name == "read" {
        if not os.path.isfile(full) {
            names = sorted([f for f in os.listdir(project_dir) if f.endswith(".jac") or f.endswith(".toml")]);
            return result("failed", path, f"failed: no file `{path}`. Files: {', '.join(names)}", "not-found");
        }
        rows = open(full).read().split("\n");
        return result("ok", path, "\n".join([f"{i + 1}│ {ln}" for (i, ln) in enumerate(rows)]));
    }
    if path not in writes {
        return result("refused", path, f"refused: this task may write only: {', '.join(writes)}.", "not-in-task");
    }
    if name == "write" {
        content = str(args.get("content", ""));
        lines = [ln for ln in content.split("\n") if ln.strip()];
        if lines and all([re.match(PREFIX, ln) is not None for ln in lines]) {
            return result("refused", path, "refused: the content has line-number prefixes. Write the file text only.", "has-prefix");
        }
        with open(full, "w") as f { f.write(content); }
        return after_change(project_dir, path, f"wrote {path} ({len(content.split(chr(10)))} lines)");
    }
    # edit
    if not os.path.isfile(full) { return result("failed", path, f"failed: no file `{path}`.", "not-found"); }
    old = strip_prefix(str(args.get("old", "")));
    new = strip_prefix(str(args.get("new", "")));
    if old == new { return result("refused", path, "refused: `old` and `new` are the same. Nothing would change.", "no-change"); }
    src = open(full).read();
    n = src.count(old) if old else 0;
    if n == 0 {
        first = old.strip().split("\n")[0] if old.strip() else "";
        close = difflib.get_close_matches(first, src.split("\n"), n=3, cutoff=0.5);
        hint = "\n".join(close) if close else "(nothing similar)";
        return result("failed", path, f"failed: `old` was not found in {path}. Closest lines in the file:\n{hint}\nRead the file and copy the text exactly.", "old-not-found");
    }
    if n > 1 { return result("failed", path, f"failed: `old` appears {n} times in {path}. Include more surrounding text so it is unique.", "old-not-unique"); }
    with open(full, "w") as f { f.write(src.replace(old, new)); }
    return after_change(project_dir, path, f"edited {path}");
}

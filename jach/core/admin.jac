"""Admin takeover (decision 0010a): a large model with a shell fixes a stalled step.

The harness, not the admin, decides whether the fix worked: it runs the same gate as `submit`.
"""
import os;
import subprocess;
import time;
import from log { RunLog }
import from tools { run_tool }
import from browse { run_actions }

glob ADMIN_FAILURES = 5;
glob ADMIN_TIMEOUT = 900;

"""Text of every project source file, keyed by relative path."""
def snapshot(project_dir: str) -> dict {
    files: dict = {};
    for name in sorted(os.listdir(project_dir)) {
        full = os.path.join(project_dir, name);
        if os.path.isfile(full) and (name.endswith(".jac") or name.endswith(".toml") or name.endswith(".css")) {
            files[name] = open(full).read();
        }
    }
    return files;
}

"""The same gate the small model faces at submit: check, wiring, then the browser actions."""
def gate(project_dir: str, port: int, actions: list[dict]) -> dict {
    res = run_tool(project_dir, [], "submit", {});
    if res["status"] != "ok" { return {"ok": False, "text": res["text"]}; }
    for r in run_actions(project_dir, port, actions) {
        if r["status"] != "ok" {
            return {"ok": False, "text": f'check: clean\nbrowser test failed in action "{r["name"]}": {r["message"]}\n{r["text"]}'};
        }
    }
    return {"ok": True, "text": "check: clean; browser actions passed"};
}

def admin_prompt(card: str, writes: list[str], failure: str, actions: list[dict]) -> str {
    steps = "\n".join([f'- {a["name"]}: {a["steps"]}' for a in actions]);
    return "You are the admin of a coding harness. A small model was building a Jac 0.36 web app in this directory and got stuck. "
        + "Finish its task with the smallest change that works.\n\n"
        + f"The task it was given:\n{card}\n\n"
        + f"The check that currently fails:\n{failure}\n\n"
        + f"After you stop, the harness runs `jac check .`, checks that main.jac imports every server name the page calls, "
        + f"and runs these browser actions on the app:\n{steps}\n\n"
        + "Rules:\n"
        + f"- Change only these files: {', '.join(writes)}.\n"
        + "- Keep what already works. Do not add features the task does not ask for.\n"
        + "- Read the Jac skills before writing (jac-core-cheatsheet, jac-cl-components, jac-fullstack-patterns, jac-debugging), or run `jac guide <name>`.\n"
        + "- Verify with `jac check .`. Do not start a server; the harness does the browser test.\n"
        + "- When done, reply with one sentence saying what was wrong.";
}

"""Run the admin once. Returns its final message."""
def call_admin(provider: str, project_dir: str, prompt: str) -> str {
    out_file = os.path.join(os.path.dirname(project_dir), "admin-last.txt");
    if provider == "claude" {
        cmd = ["claude", "-p", prompt, "--model", "claude-opus-5-5", "--permission-mode", "acceptEdits",
               "--allowedTools", "Read", "Edit", "Write", "Glob", "Grep", "Skill", "Bash(jac:*)"];
    } else {
        cmd = ["codex", "exec", "-C", project_dir, "-s", "workspace-write", "--skip-git-repo-check", "--ephemeral", "-o", out_file, prompt];
    }
    try {
        p = subprocess.run(cmd, cwd=project_dir, capture_output=True, text=True, timeout=ADMIN_TIMEOUT, stdin=subprocess.DEVNULL);
    } except subprocess.TimeoutExpired {
        return "(admin timed out)";
    }
    if provider != "claude" and os.path.isfile(out_file) { return open(out_file).read().strip(); }
    return (p.stdout or p.stderr).strip()[-2000:];
}

"""Takeover rung: the admin edits until the gate passes or it has failed ADMIN_FAILURES times."""
def takeover(log: RunLog, provider: str, project_dir: str, card: str, writes: list[str], failure: str, port: int, actions: list[dict]) -> dict {
    log.event("escalate", "harness", {"tier": "takeover", "provider": provider});
    current = failure;
    for attempt in range(1, ADMIN_FAILURES + 1) {
        before = snapshot(project_dir);
        prompt = admin_prompt(card, writes, current, actions);
        log.event("request", "admin", {"attempt": attempt, "prompt": prompt});
        t0 = time.time();
        said = call_admin(provider, project_dir, prompt);
        log.event("reply", "admin", {"attempt": attempt, "raw": said, "sec": round(time.time() - t0, 1)});
        after = snapshot(project_dir);
        changed = [name for name in after if before.get(name) != after[name]];
        for name in changed { log.event("file", "admin", {"path": name, "content": after[name]}); }
        g = gate(project_dir, port, actions);
        log.event("tool", "harness", {"tool": "submit", "target": "step", "status": "ok" if g["ok"] else "failed", "result": g["text"], "after": "admin"});
        print(f"  [admin {attempt}] changed {', '.join(changed) or 'nothing'} -> {'ok' if g['ok'] else 'failed'}   [{round(time.time() - t0)} s] {said[:160]}");
        if g["ok"] { return {"ok": True, "attempts": attempt, "said": said}; }
        current = g["text"];
    }
    return {"ok": False, "attempts": ADMIN_FAILURES, "said": ""};
}

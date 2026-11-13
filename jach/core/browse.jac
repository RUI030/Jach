"""Run action steps (open, fill, click, expect) against the app in a headless browser (decisions 0004, 0006)."""
import os;
import re;
import time;
import signal;
import shutil;
import subprocess;
import from urllib.request { urlopen }

def sh(args: list[str], cwd: str, timeout: int = 60) -> str {
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout);
    return p.stdout + p.stderr;
}

def http_status(url: str) -> int {
    try { return urlopen(url, timeout=3).status; } except Exception as e { return getattr(e, "code", 0) or 0; }
}

"""Find the @eN reference of the first element whose line contains the label."""
def find_ref(snapshot: str, label: str) -> str {
    for line in snapshot.split("\n") {
        if f'"{label}"' in line {
            m = re.search(r"@e\d+", line);
            if m and ("button" in line or "textbox" in line or "link" in line) { return m.group(0); }
        }
    }
    return "";
}

"""Wait until the snapshot satisfies `want`, up to `limit` seconds. Returns the last snapshot."""
def wait_snapshot(cwd: str, want: str, limit: float = 10.0) -> str {
    end = time.time() + limit;
    snap = "";
    while time.time() < end {
        snap = sh(["jac", "browse", "snapshot"], cwd);
        if want in snap { return snap; }
        time.sleep(0.5);
    }
    return snap;
}

"""The text a user sees on the page, with runs of whitespace joined to one space."""
def page_text(cwd: str) -> str {
    return " ".join(sh(["jac", "browse", "eval", "document.body.innerText"], cwd).split());
}

"""Wait until `want` is in the visible text, up to `limit` seconds."""
def wait_text(cwd: str, want: str, limit: float = 10.0) -> bool {
    end = time.time() + limit;
    while time.time() < end {
        if want in page_text(cwd) { return True; }
        time.sleep(0.5);
    }
    return False;
}

"""Run the steps of one action against a running app."""
def run_steps(project_dir: str, base: str, steps: list[list[str]]) -> dict {
    done: list[str] = [];
    status = "ok";
    message = "";
    for step in steps {
        verb = step[0];
        arg = step[1];
        if verb == "open" {
            sh(["jac", "browse", "open", base + arg], project_dir);
            wait_snapshot(project_dir, "RootWebArea");
        } elif verb == "click" or verb == "fill" {
            snap = wait_snapshot(project_dir, f'"{arg}"');
            ref = find_ref(snap, arg);
            if not ref { status = "failed"; message = f'{verb} "{arg}": no such element on the page'; break; }
            if verb == "click" { sh(["jac", "browse", "click", ref], project_dir); }
            else { sh(["jac", "browse", "fill", ref, step[2]], project_dir); }
        } elif verb == "press" {
            sh(["jac", "browse", "press", arg], project_dir);
        } elif verb == "wait" {
            time.sleep(float(arg));
        } elif verb == "expect_not" {
            time.sleep(1.0);
            if arg in page_text(project_dir) { status = "failed"; message = f'expect_not "{arg}": text is on the page'; break; }
        } elif verb == "expect" {
            if not wait_text(project_dir, arg) { status = "failed"; message = f'expect "{arg}": text not on the page'; break; }
        }
        done.append(" ".join(step) + " -> ok");
    }
    console = sh(["jac", "browse", "console"], project_dir);
    errs = [ln for ln in console.split("\n") if "[error]" in ln and "favicon.ico" not in ln];
    if status == "failed" and errs { message += "; " + errs[0][:200]; }
    if status == "failed" {
        snap = sh(["jac", "browse", "snapshot"], project_dir);
        done.append("page at failure:\n" + snap[:1500]);
    }
    return {"status": status, "message": message, "text": "\n".join(done)};
}

"""Start the app once, run every action, stop the app."""
def run_actions(project_dir: str, port: int, actions: list[dict]) -> list[dict] {
    base = f"http://127.0.0.1:{port}";
    # Jac keys an app's stored data by its directory, in a machine-wide store. A fresh copy means empty data.
    src_dir = project_dir;
    project_dir = f"{src_dir}-gate-{time.time_ns()}";
    shutil.copytree(src_dir, project_dir, symlinks=True);
    results: list[dict] = [];
    # The server is restarted before the last action, data kept: state held only in memory does not pass.
    groups = [actions[:-1], actions[-1:]] if len(actions) > 1 else [actions];
    for (gi, group) in enumerate(groups) {
        logf = open(os.path.join(project_dir, ".jach-server.log"), "a");
        server = subprocess.Popen(["jac", "start", "main.jac", "--port", str(port)], cwd=project_dir, stdin=subprocess.DEVNULL, stdout=logf, stderr=subprocess.STDOUT, start_new_session=True);
        try {
            ready = False;
            for i in range(90) {
                if http_status(base + "/static/client.js") == 200 { ready = True; break; }
                time.sleep(2);
            }
            if not ready {
                shutil.rmtree(project_dir, ignore_errors=True);
                return results + [{"name": a["name"], "status": "failed", "message": "the app did not start: /static/client.js never returned 200", "text": ""} for a in group];
            }
            for a in group {
                r = run_steps(project_dir, base, a["steps"]);
                r["name"] = a["name"];
                if gi == 1 and r["status"] != "ok" { r["message"] = "after a server restart: " + r["message"]; }
                results.append(r);
            }
            sh(["jac", "browse", "close"], project_dir);
        } finally {
            os.killpg(server.pid, signal.SIGTERM);
            logf.close();
            time.sleep(2);
        }
    }
    shutil.rmtree(project_dir, ignore_errors=True);
    return results;
}

"""Run action steps (open, fill, click, expect) against the app in a headless browser (decisions 0004, 0006)."""
import os;
import re;
import time;
import signal;
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

def run_action(project_dir: str, port: int, steps: list[list[str]]) -> dict {
    base = f"http://127.0.0.1:{port}";
    logf = open(os.path.join(project_dir, ".jach-server.log"), "w");
    server = subprocess.Popen(["jac", "start", "main.jac", "--port", str(port)], cwd=project_dir, stdin=subprocess.DEVNULL, stdout=logf, stderr=subprocess.STDOUT, start_new_session=True);
    done: list[str] = [];
    status = "ok";
    message = "";
    try {
        ready = False;
        for i in range(90) {
            if http_status(base + "/static/client.js") == 200 { ready = True; break; }
            time.sleep(2);
        }
        if not ready {
            status = "failed"; message = "the app did not start: /static/client.js never returned 200";
        } else {
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
                } elif verb == "expect" {
                    snap = wait_snapshot(project_dir, arg);
                    if arg not in snap { status = "failed"; message = f'expect "{arg}": text not on the page'; break; }
                }
                done.append(" ".join(step) + " -> ok");
            }
        }
        console = sh(["jac", "browse", "console"], project_dir);
        errs = [ln for ln in console.split("\n") if "[error]" in ln and "favicon.ico" not in ln];
        if status == "failed" and errs { message += "; " + errs[0][:160]; }
        sh(["jac", "browse", "close"], project_dir);
    } finally {
        os.killpg(server.pid, signal.SIGTERM);
        logf.close();
    }
    return {"status": status, "message": message, "text": "\n".join(done)};
}

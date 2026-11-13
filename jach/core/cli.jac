"""CLI entry: run one task on a fresh copy of the template."""
import os;
import json;
import sys;
import time;
import shutil;
import subprocess;
import from tree { Project, Feature, Task, Step, Has }
import from log { RunLog }
import from session { Session }
import from browse { run_actions }
import from admin { takeover }

with entry {
    here_dir = os.path.dirname(os.path.abspath(__file__));
    repo = os.path.dirname(os.path.dirname(here_dir));
    run_id = time.strftime("%Y%m%d-%H%M%S");
    run_dir = os.path.join(repo, "runs", run_id);
    project_dir = os.path.join(run_dir, "project");
    shutil.copytree(os.path.join(repo, "jach", "template"), project_dir, ignore=shutil.ignore_patterns("README.md", ".jac"));
    server = os.environ.get("JACH_MODEL_SERVER", "http://127.0.0.1:8791");

    log = RunLog(run_dir=run_dir);
    log.meta({"run": run_id, "jac": "0.36.1", "model_server": server, "limits": {"failures": 5, "same_error": 3, "step_tokens": 32000}, "fold": "failures-only"});

    spec_path = sys.argv[-1] if sys.argv[-1].endswith(".json") else os.path.join(repo, "jach", "tasks", "level1-hello.json");
    spec = json.loads(open(spec_path).read());
    goal = spec["goal"];
    p = Project(name="app", dir=project_dir);
    f = Feature(fid="F1", title=spec["title"]);
    t = Task(tid="T01", title=spec["title"], goal=goal, writes=spec["writes"]);
    s = Step(kind="task");
    root +>:Has:+> p; p +>:Has:+> f; f +>:Has:+> t; t +>:Has:+> s;

    log.event("run", "harness", {"requirement": goal, "task_spec": spec["id"]});
    print(f"run {run_id}");
    feedback = os.environ.get("JACH_BROWSER_FEEDBACK", "1") == "1";
    dry = os.environ.get("JACH_DRY", "") == "1";
    guide = "";
    if os.environ.get("JACH_GUIDE", "") {
        guide = subprocess.run(["jac", "guide", os.environ["JACH_GUIDE"]], capture_output=True, text=True).stdout;
    }
    log.event("run", "harness", {"settings": {"dry": dry, "guide": os.environ.get("JACH_GUIDE", ""), "browser_feedback": feedback}});
    port = int(os.environ.get("JACH_PORT", "8795"));
    admin = os.environ.get("JACH_ADMIN", "");
    w = t spawn Session(server=server, log=log, project_dir=project_dir, actions=spec["actions"] if feedback else [], dry=dry, guide=guide, port=port);
    log.event("run", "harness", {"outcome": w.outcome, "turns": w.n});
    print(f"outcome: {w.outcome} | turns: {w.n} | log: {run_dir}/events.jsonl");
    outcome = w.outcome;
    if admin and outcome.startswith("stalled") {
        failure = w.turns[-1]["result"] if w.turns else "";
        fix = takeover(log, admin, project_dir, w.card, spec["writes"], failure, port, spec["actions"]);
        outcome = f"admin-fixed:{fix['attempts']}" if fix["ok"] else "failed";
        log.event("run", "harness", {"outcome": outcome});
    }
    log.at({"session": "", "task": "T01", "step": "e2e"});
    e2e = run_actions(project_dir, port, spec["actions"]);
    for r in e2e {
        log.event("tool", "harness", {"tool": "browse", "target": r["name"], "status": r["status"], "message": r["message"], "result": r["text"]});
        print(f"e2e {r['name']}: {r['status']} {r['message']}");
    }
    passed = all([r["status"] == "ok" for r in e2e]);
    log.event("run", "harness", {"e2e": "passed" if passed else "failed"});
    print("RESULT", spec["id"], "harness=" + outcome, "browser=" + ("passed" if passed else "failed"), "turns=" + str(w.n));
}

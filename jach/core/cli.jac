"""CLI entry: run one task on a fresh copy of the template."""
import os;
import sys;
import time;
import shutil;
import from tree { Project, Feature, Task, Step, Has }
import from log { RunLog }
import from session { Session }
import from browse { run_action }

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

    goal = "Add a server function `hello` in server.jac that returns the text \"Hello from Jac\". "
        + "Add a button labelled \"Hello\" to the page in frontend.jac. When it is clicked, the page shows the text returned by `hello`. "
        + "Keep the existing Ping button working.";
    if os.environ.get("JACH_HINT", "") { goal += " Remember that main.jac must import every server function the page calls."; }
    p = Project(name="app", dir=project_dir);
    f = Feature(fid="F1", title="Hello button");
    t = Task(tid="T01", title="Hello button", goal=goal, writes=["server.jac", "frontend.jac", "main.jac"]);
    s = Step(kind="task");
    root +>:Has:+> p; p +>:Has:+> f; f +>:Has:+> t; t +>:Has:+> s;

    log.event("run", "harness", {"requirement": goal});
    print(f"run {run_id}");
    w = t spawn Session(server=server, log=log, project_dir=project_dir);
    log.event("run", "harness", {"outcome": w.outcome, "turns": w.n});
    print(f"outcome: {w.outcome} | turns: {w.n} | log: {run_dir}/events.jsonl");
    log.at({"session": "", "task": "T01", "step": "e2e"});
    steps = [["open", "/"], ["click", "Hello"], ["expect", "Hello from Jac"], ["click", "Ping"], ["expect", "pong"]];
    e2e = run_action(project_dir, 8795, steps);
    log.event("tool", "harness", {"tool": "browse", "status": e2e["status"], "message": e2e["message"], "result": e2e["text"]});
    print(f"e2e: {e2e['status']} {e2e['message']}");
}

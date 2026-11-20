"""CLI entry: run one task spec on a fresh copy of the template, or resume an earlier run.

  jac run jach/core/cli.jac <spec.json>
Settings (environment): JACH_MODEL_SERVER, JACH_PORT, JACH_PLAN=1 (plan first when the spec has no task list),
JACH_RESUME=<run dir> (continue that run's project and task list), JACH_ADMIN, JACH_ADMIN_ONLY=1,
JACH_BROWSER_FEEDBACK (default 1), JACH_DRY=1,
JACH_ATTEMPTS (sessions per task, default 2), JACH_TUNED=1 (the model was trained on this Jac version: no read-first request, no preloaded pitfalls)."""
import os;
import json;
import sys;
import time;
import shutil;
import subprocess;
import from log { RunLog }
import from browse { run_actions }
import from admin { takeover }
import from check { jac_version, project_files, test_blocks }
import from commands { run_suite }
import from runner { run_project, MAX_ATTEMPTS }

with entry {
    here_dir = os.path.dirname(os.path.abspath(__file__));
    repo = os.path.dirname(os.path.dirname(here_dir));
    resume = os.environ.get("JACH_RESUME", "");
    spec_path = sys.argv[-1] if sys.argv[-1].endswith(".json") else os.path.join(repo, "jach", "tasks", "level1-hello.json");
    spec = json.loads(open(spec_path).read());
    if resume {
        run_dir = os.path.abspath(resume);
        run_id = os.path.basename(run_dir.rstrip("/"));
        project_dir = os.path.join(run_dir, "project");
        if os.path.isfile(os.path.join(run_dir, "tasks.json")) { spec["tasks"] = json.loads(open(os.path.join(run_dir, "tasks.json")).read()); }
    } else {
        run_id = time.strftime("%Y%m%d-%H%M%S");
        run_dir = os.path.join(repo, "runs", run_id);
        project_dir = os.path.join(run_dir, "project");
        # The scaffold comes from the installed Jac (`jac create`), so it follows the version; our files go on top.
        os.makedirs(run_dir, exist_ok=True);
        made = subprocess.run(["jac", "create", "project", "--use", "jac-shadcn"], cwd=run_dir, capture_output=True, text=True, timeout=600);
        if made.returncode != 0 { print("jac create failed:\n" + made.stdout[-2000:] + made.stderr[-2000:]); sys.exit(1); }
        for extra in ["AGENTS.md"] { if os.path.isfile(os.path.join(project_dir, extra)) { os.remove(os.path.join(project_dir, extra)); } }
        ours = ["main.jac", "server.jac", "frontend.jac"];
        # The scaffold's own Jac files, so the description rule and hard warnings skip them (check.own_files).
        with open(os.path.join(project_dir, ".jach-scaffold"), "w") as f { f.write("\n".join([p for p in project_files(project_dir) if p not in ours])); }
        for name in ours { shutil.copy(os.path.join(repo, "jach", "template", name), os.path.join(project_dir, name)); }
    }
    server = os.environ.get("JACH_MODEL_SERVER", "http://127.0.0.1:8791");
    port = int(os.environ.get("JACH_PORT", "8795"));
    admin = os.environ.get("JACH_ADMIN", "");
    opts = {"plan": os.environ.get("JACH_PLAN", "") == "1", "resume": bool(resume), "feedback": os.environ.get("JACH_BROWSER_FEEDBACK", "1") == "1",
            "dry": os.environ.get("JACH_DRY", "") == "1", "port": port, "admin": admin};

    log = RunLog(run_dir=run_dir);
    log.meta({"run": run_id, "jac": jac_version(), "model_server": server, "limits": {"failures": 5, "turns": 40, "step_tokens": 32000, "attempts": MAX_ATTEMPTS}, "fold": "failures-only"});
    log.event("run", "harness", {"requirement": spec["goal"], "task_spec": spec["id"],
              "settings": {"tuned": os.environ.get("JACH_TUNED", "0") == "1", "plan": opts["plan"], "resume": resume, "dry": opts["dry"], "browser_feedback": opts["feedback"]}});
    print(f"run {run_id}");
    if os.environ.get("JACH_ADMIN_ONLY", "") == "1" {
        card = f"Task T01: {spec['title']}\nGoal: {spec['goal']}";
        fix = takeover(log, admin or "codex", project_dir, card, "Nothing is written yet; the project is the unchanged template.", port, spec["actions"]);
        print("RESULT", spec["id"], "reference=" + ("ok:" + str(fix["attempts"]) if fix["ok"] else "failed"));
        sys.exit(0);
    }
    out = run_project(spec, project_dir, run_dir, log, server, opts);
    log.event("run", "harness", {"outcome": out["outcome"], "turns": out["turns"]});
    for t in out["tasks"] { print(f"task {t.tid} {t.title}: {t.status} ({t.attempts} attempts) {t.note}"); }
    print(f"outcome: {out['outcome']} | turns: {out['turns']} | log: {run_dir}/events.jsonl");
    log.at({"session": "", "task": "", "step": "e2e"});
    e2e = run_actions(project_dir, port, spec["actions"]);
    for r in e2e {
        log.event("tool", "harness", {"tool": "browse", "target": r["name"], "status": r["status"], "message": r["message"], "result": r["text"]});
        print(f"e2e {r['name']}: {r['status']} {r['message']}");
    }
    passed = all([r["status"] == "ok" for r in e2e]);
    log.event("run", "harness", {"e2e": "passed" if passed else "failed"});
    # The whole test suite on the finished app; "none" when the run wrote no tests.
    tests_out = "none";
    if test_blocks(project_dir) {
        st = run_suite(project_dir);
        tests_out = f"{len([v for v in st['rows'].values() if v == 'passed'])}/{len(test_blocks(project_dir))}";
    }
    log.event("run", "harness", {"tests": tests_out});
    print("RESULT", spec["id"], "harness=" + out["outcome"], "browser=" + ("passed" if passed else "failed"), "tests=" + tests_out, "turns=" + str(out["turns"]));
}

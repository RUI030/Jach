"""Gate only: run the checks and the browser actions of a task spec on a finished project, whoever wrote it."""
import os;
import sys;
import json;
import from check { first_error, wiring, descriptions, own_files }
import from browse { run_actions }

with entry {
    # Optional last argument "any": the app may be in any stack and starts with ./start.sh; Jac checks are skipped.
    any_stack = sys.argv[-1] == "any";
    args: list[str] = [str(a) for a in (sys.argv[:-1] if any_stack else sys.argv)];
    project_dir = os.path.abspath(args[-3]);
    spec = json.loads(open(args[-2]).read());
    port = int(args[-1]);
    checks: dict = {};
    mine = own_files(project_dir);
    for (name, fn) in ([] if any_stack else [("compile", first_error), ("wiring", wiring), ("descriptions", descriptions)]) {
        r = fn(project_dir, ".", mine) if name == "compile" else (fn(project_dir) if name == "wiring" else fn(project_dir, mine));
        checks[name] = "clean" if r["clean"] else f"{r['code']} {r['message']}";
    }
    e2e = run_actions(project_dir, port, spec["actions"], ["sh", "start.sh"] if any_stack else []);
    out = {"spec": spec["id"], "checks": checks, "browser": "passed" if all([r["status"] == "ok" for r in e2e]) else "failed",
           "actions": [{"name": r["name"], "status": r["status"], "message": r["message"]} for r in e2e]};
    print("GATE " + json.dumps(out));
}

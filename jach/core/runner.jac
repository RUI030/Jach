"""Run a project: an optional Plan session, then each task in its own fresh session (decisions 0004, 0005).
Task status comes from checks the harness runs; the handover between attempts is facts the harness saw."""
import os;
import json;
import from tree { Project, Feature, Task, Step, Has }
import from log { RunLog }
import from session { Session }
import from tools { run_tool }
import from check { missing_bodies, entry_of, open_endpoints, test_blocks }
import from planning { assign_tests, named_in }
import from commands { run_suite }
import from browse { run_actions }
import from admin { takeover, snapshot }

glob MAX_ATTEMPTS = int(os.environ.get("JACH_ATTEMPTS", "2"));  # setting: fresh sessions per task before it counts as stalled

"""Files whose text differs between two snapshots."""
def changed_files(before: dict, after: dict) -> list[str] {
    return sorted([p for p in set(list(before.keys()) + list(after.keys())) if before.get(p) != after.get(p)]);
}

"""One browser action as one line: its name and its steps."""
def action_line(a: dict) -> str {
    return f"  {a['name']}: " + "; ".join([" ".join(s) for s in a["steps"]]);
}

"""The checks submit runs, in order, as the card's `Done when` list (the same order as tools.run_tool and Session.act).
`earlier` are the finished tasks' actions: submit runs them again, so a task cannot break what is done."""
def done_when(t: Task, bare: list[str], entry_file: str, earlier: list[dict], with_actions: bool, earlier_tests: list[str] = []) -> str {
    rows = ["jac check passes on the whole project",
            f"{entry_file} imports every server function the client calls",
            "every public def and walker has a one-sentence description above it"];
    if bare { rows.append("these have bodies: " + ", ".join(bare)); }
    if t.tests { rows.append("these tests pass (written before the tasks, in .test.jac files, which cannot change): " + ", ".join([f'"{n}"' for n in t.tests])); }
    if earlier_tests { rows.append("the finished tasks' tests still pass: " + ", ".join([f'"{n}"' for n in earlier_tests])); }
    if with_actions and t.actions { rows.append("these browser actions pass, each on a fresh copy of the app:\n" + "\n".join(["   " + action_line(a) for a in t.actions])); }
    if with_actions and earlier { rows.append("the finished tasks' actions still pass: " + ", ".join([a["name"] for a in earlier])); }
    return "Done when (submit checks these in order and stops at the first that fails):\n" + "\n".join([f"  {i + 1}. {r}" for (i, r) in enumerate(rows)]);
}

"""The task card: what to do, what is done, what earlier attempts ended with, and when it is done."""
def task_intro(t: Task, requirement: str, done: list[Task], attempts: list[dict], bare: list[str], entry_file: str, with_actions: bool) -> str {
    s = f"App: {requirement}\n\n" if requirement else "";
    s += f"Task {t.tid}: {t.title}\nGoal: {t.goal}";
    if bare { s += f"\nGive bodies to: {', '.join(bare)}. They are declared already; keep each signature and write its body in place of the `;`."; }
    changed = [n for n in t.implements if n not in bare];
    if changed { s += f"\nChange: {', '.join(changed)}. They have bodies already; rewrite them as the goal needs."; }
    if done { s += "\nDone already: " + "; ".join([f"{d.tid} {d.title}" for d in done]); }
    for a in attempts {
        s += f"\nEarlier attempt {a['n']}: {a['outcome']} after {a['turns']} replies; files changed: {', '.join(a['changed']) or 'none'}; last result: {a['last']}";
    }
    return s + "\n\n" + done_when(t, bare, entry_file, [a for d in done for a in d.actions], with_actions, [n for d in done for n in d.tests]);
}

"""The card head of the Plan session."""
def plan_intro(spec: dict) -> str {
    return (f"Requirement: {spec['goal']}\n\n"
        + "Browser actions the finished app must pass:\n" + "\n".join([action_line(a) for a in spec["actions"]]) + "\n\n"
        + "Plan it in three steps:\n"
        + "1. Read the app's files, then declare in them what the app needs: each node with its fields, and each function with a description, a typed signature and no body, ending in `;`, such as `def:pub add_item(title: str) -> Item;`. Keep the code that is already there.\n"
        + "2. Call add_task once per task. A task delivers one or more of the actions above; in implements, name the functions it gives bodies to and the existing functions it changes, such as the page component. Add a task only after the tasks it depends on.\n"
        + "3. Call submit. It checks the declarations, that every function without a body is in exactly one task, and that every action is in exactly one task.");
}

"""The card of the Tests session: what to test, where, and when it is done."""
def tests_intro(spec: dict, required: list[str]) -> str {
    return (f"Requirement: {spec['goal']}\n\n"
        + f"Write the unit tests now, before any body exists. Functions to test, declared without bodies: {', '.join(required)}. "
        + "Read their declarations and descriptions, then test what each description promises: the values it returns and what it stores.\n"
        + "Put the tests in `<module>.test.jac` next to the module that declares the functions, such as `server.test.jac` for `server.jac`; "
        + "it sees that module's declarations without imports. guide(topic=\"jac-testing\") shows how tests are written. "
        + "Tests in one run share stored data, so each test checks what it created itself, not totals.\n\n"
        + "Done when (submit checks these in order and stops at the first that fails):\n"
        + "  1. jac check passes on the whole project\n"
        + "  2. every public def and walker has a one-sentence description above it\n"
        + "  3. every test is in a .test.jac file\n"
        + f"  4. each of these is called in at least one test: {', '.join(required)}\n"
        + "  5. they still have no bodies\n"
        + "  6. every test fails now: with no bodies written, a test that passes tests nothing");
}

"""The harness's own check that a task is done, used on resume: submit's checks, bodies, browser actions."""
def task_passes(project_dir: str, t: Task, port: int) -> bool {
    if run_tool(project_dir, "submit", {}, port)["status"] != "ok" { return False; }
    if missing_bodies(project_dir, t.implements) { return False; }
    if t.tests and not all([run_suite(project_dir)["rows"].get(n) == "passed" for n in t.tests]) { return False; }
    return all([r["status"] == "ok" for r in run_actions(project_dir, port, t.actions)]) if t.actions else True;
}

"""The task list as data and as a page for people (decision 0005 section 3)."""
def save_tasks(run_dir: str, tasks: list[Task]) {
    rows = [{"id": t.tid, "title": t.title, "goal": t.goal, "implements": t.implements,
             "depends_on": t.depends_on, "actions": [a["name"] for a in t.actions], "tests": t.tests, "status": t.status, "attempts": t.attempts, "note": t.note} for t in tasks];
    with open(os.path.join(run_dir, "tasks.json"), "w") as f { f.write(json.dumps(rows, indent=2)); }
    md = "| Task | Title | After | Status | Attempts | Note |\n|---|---|---|---|---|---|\n"
        + "\n".join([f"| {r['id']} | {r['title']} | {', '.join(r['depends_on'])} | {r['status']} | {r['attempts']} | {r['note']} |" for r in rows]);
    with open(os.path.join(run_dir, "tasks.md"), "w") as f { f.write(md + "\n"); }
}

"""Run the whole project. `opts`: plan, resume, feedback, dry, port, admin. Returns outcome, turns, tasks."""
def run_project(spec: dict, project_dir: str, run_dir: str, log: RunLog, server: str, opts: dict) -> dict {
    p = Project(name="app", dir=project_dir, brief=spec["goal"]);
    f = Feature(fid="F1", title=spec["title"]);
    root +>:Has:+> p;
    p +>:Has:+> f;
    by_name = {a["name"]: a for a in spec["actions"]};
    port = opts["port"];
    turns = 0;
    if spec.get("tasks") {
        plan_rows = spec["tasks"];
    } elif opts["plan"] {
        pt = Task(tid="PLAN", title="Plan", goal=spec["goal"]);
        f +>:Has:+> pt;
        pt +>:Has:+> Step(kind="plan");
        w = pt spawn Session(server=server, log=log, project_dir=project_dir, sid="PLAN", phase="plan", intro=plan_intro(spec),
                             actions=spec["actions"], dry=opts["dry"], port=port);
        turns += w.n;
        pt.status = "passed" if w.outcome == "passed" else "stalled";
        log.event("plan", "harness", {"outcome": w.outcome, "tasks": w.tasks});
        if w.outcome != "passed" { return {"outcome": "stalled:plan", "turns": turns, "tasks": []}; }
        plan_rows = w.tasks;
    } else {
        plan_rows = [{"id": "T01", "title": spec["title"], "goal": spec["goal"], "actions": list(by_name.keys())}];
    }
    tasks: list[Task] = [];
    for r in plan_rows {
        t = Task(tid=r["id"], title=r["title"], goal=r["goal"], implements=r.get("implements", []),
                 depends_on=r.get("depends_on", []), actions=[by_name[n] for n in r.get("actions", []) if n in by_name]);
        f +>:Has:+> t;
        tasks.append(t);
    }
    # Tests phase (decision 0004): tests for the server functions still without a body, written before any body and frozen after.
    tested = [n for b in test_blocks(project_dir) for n in named_in(b["body"], open_endpoints(project_dir))];
    required = [n for n in open_endpoints(project_dir) if n not in tested];
    if required {
        tt = Task(tid="TESTS", title="Tests", goal=spec["goal"], implements=required);
        f +>:Has:+> tt;
        tt +>:Has:+> Step(kind="tests");
        w = tt spawn Session(server=server, log=log, project_dir=project_dir, sid="TESTS", phase="tests", intro=tests_intro(spec, required),
                             dry=opts["dry"], port=port);
        turns += w.n;
        tt.status = "passed" if w.outcome == "passed" else "stalled";
        log.event("tests", "harness", {"outcome": w.outcome, "tests": [b["name"] for b in test_blocks(project_dir)]});
        if w.outcome != "passed" { return {"outcome": "stalled:tests", "turns": turns, "tasks": []}; }
    }
    owned = assign_tests(project_dir, [(t.tid, t.implements) for t in tasks]);
    for t in tasks { t.tests = owned.get(t.tid, []); }
    frozen = any([t.tests for t in tasks]);
    if opts["resume"] {
        # Never trust a stored status: re-run each task's checks.
        for t in tasks { t.status = "passed" if task_passes(project_dir, t, port) else "pending"; }
        log.event("resume", "harness", {"passed": [t.tid for t in tasks if t.status == "passed"]});
    }
    save_tasks(run_dir, tasks);
    requirement = spec["goal"] if len(tasks) > 1 else "";
    while True {
        done = [t for t in tasks if t.status == "passed"];
        ready = [t for t in tasks if t.status == "pending" and all([d in [x.tid for x in done] for d in t.depends_on])];
        if not ready { break; }
        t = ready[0];  # plan order
        # Read once when the task starts: which of its functions still have no body.
        bare = missing_bodies(project_dir, t.implements);
        attempts: list[dict] = [];
        card = "";
        while t.attempts < MAX_ATTEMPTS {
            t.attempts += 1;
            t +>:Has:+> Step(kind="task");
            before = snapshot(project_dir);
            w = t spawn Session(server=server, log=log, project_dir=project_dir, sid=f"{t.tid}-{t.attempts}",
                                intro=task_intro(t, requirement, done, attempts, bare, entry_of(project_dir), opts["feedback"]), actions=(t.actions + [a for d in done for a in d.actions] if opts["feedback"] else []),
                                tests=t.tests + [n for d in done for n in d.tests], frozen=frozen,
                                dry=opts["dry"], port=port);
            turns += w.n;
            card = w.card;
            if w.outcome == "passed" { t.status = "passed"; break; }
            # The last failure in the harness's own words: the tool, its error code and message.
            bad = [x for x in w.turns if x["status"] not in ["ok", "not-run"]];
            last = f"{bad[-1]['tool']} {bad[-1]['target']}: {bad[-1]['code']} {bad[-1]['message']}".strip()[:300] if bad else "none";
            attempts.append({"n": t.attempts, "outcome": w.outcome, "turns": w.n, "changed": changed_files(before, snapshot(project_dir)), "last": last});
            t.status = "pending";
        }
        if t.status != "passed" and opts["admin"] {
            fix = takeover(log, opts["admin"], project_dir, card, attempts[-1]["last"] if attempts else "", port, t.actions, t.tests + [n for d in done for n in d.tests]);
            if fix["ok"] { t.status = "passed"; t.note = f"admin fixed in {fix['attempts']}"; }
        }
        if t.status != "passed" {
            t.status = "stalled";
            t.note = "; ".join([f"attempt {a['n']}: {a['outcome']}" for a in attempts]);
        }
        log.event("task", "harness", {"task": t.tid, "status": t.status, "attempts": t.attempts, "note": t.note});
        save_tasks(run_dir, tasks);
    }
    left = [t.tid for t in tasks if t.status != "passed"];
    return {"outcome": "passed" if not left else "stalled:" + ",".join(left), "turns": turns, "tasks": tasks};
}

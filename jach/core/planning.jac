"""The task list the model builds in Plan, and the checks on it (decisions 0004, 0005).
A task is a dict: id, title, goal, implements (names), depends_on (task ids), actions (brief action names)."""
import re;
import from check { declared_names, missing_bodies, entry_of, test_blocks }
import from commands { run_suite, not_ran_text }

"""Names in a model's list argument: separated by commas, spaces or new lines."""
def names_in(text: str) -> list[str] {
    return [n for n in re.split(r"[\s,]+", text.strip()) if n];
}

"""Functions declared without a body anywhere in the project: each must belong to one task."""
def open_names(project_dir: str) -> list[str] {
    return missing_bodies(project_dir, list(declared_names(project_dir).keys()));
}

"""What still keeps the plan from passing, as short lines."""
def plan_problems(project_dir: str, tasks: list[dict], actions: list[dict]) -> list[str] {
    out: list[str] = [];
    if not tasks { out.append("no task yet: call add_task"); }
    owned: dict = {};
    for t in tasks { for n in t["implements"] { owned.setdefault(n, []).append(t["id"]); } }
    for n in open_names(project_dir) {
        if n not in owned { out.append(f"`{n}` is declared without a body but no task implements it"); }
        elif len(owned[n]) > 1 { out.append(f"`{n}` is in more than one task: {', '.join(owned[n])}"); }
    }
    for a in actions {
        who = [t["id"] for t in tasks if a["name"] in t["actions"]];
        if not who { out.append(f"action \"{a['name']}\" belongs to no task"); }
        elif len(who) > 1 { out.append(f"action \"{a['name']}\" is in more than one task: {', '.join(who)}"); }
    }
    return out;
}

"""The task list as text, one task per line."""
def list_text(tasks: list[dict]) -> str {
    if not tasks { return "Tasks: (none)"; }
    rows = [f"  {t['id']}: {t['title']}  implements: {', '.join(t['implements']) or '-'}  after: {', '.join(t['depends_on']) or '-'}  actions: {', '.join(t['actions']) or '-'}" for t in tasks];
    return "Tasks:\n" + "\n".join(rows);
}

"""The list and what still fails, appended to every task-list tool result."""
def status_text(project_dir: str, tasks: list[dict], actions: list[dict]) -> str {
    probs = plan_problems(project_dir, tasks, actions);
    return list_text(tasks) + ("\nStill to do:\n" + "\n".join(["  " + p for p in probs]) if probs else "\nThe plan is complete; call submit.");
}

"""The `add_task` tool. Earlier tasks only in depends_on, so the list can never have a cycle."""
def add_task(project_dir: str, tasks: list[dict], args: dict, actions: list[dict]) -> dict {
    tid = str(args.get("id", "")).strip();
    title = str(args.get("title", "")).strip();
    goal = str(args.get("goal", "")).strip();
    impl_names = names_in(str(args.get("implements", "")));
    deps = names_in(str(args.get("depends_on", "")));
    acts = [a.strip() for a in str(args.get("actions", "")).split("\n") if a.strip()];
    if not tid or not title or not goal { return {"ok": False, "text": "failed: id, title and goal are required."}; }
    if tid in [t["id"] for t in tasks] { return {"ok": False, "text": f"failed: task {tid} exists; drop_task it first to change it.\n" + list_text(tasks)}; }
    where = declared_names(project_dir);
    unknown = [n for n in impl_names if n not in where];
    if unknown {
        return {"ok": False, "text": f"failed: not declared in any file: {', '.join(unknown)}. Declare it first. Declared: {', '.join(sorted(where.keys()))}"};
    }
    later = [d for d in deps if d not in [t["id"] for t in tasks]];
    if later { return {"ok": False, "text": f"failed: depends_on names tasks not added yet: {', '.join(later)}. Add the tasks it depends on first."}; }
    names = [a["name"] for a in actions];
    bad = [a for a in acts if a not in names];
    if bad { return {"ok": False, "text": f"failed: no action named {', '.join(bad)}. Actions: {', '.join(names)}"}; }
    tasks.append({"id": tid, "title": title, "goal": goal, "implements": impl_names, "depends_on": deps, "actions": acts});
    return {"ok": True, "text": f"added {tid}\n" + status_text(project_dir, tasks, actions)};
}

"""The `drop_task` tool. A task others depend on cannot be dropped."""
def drop_task(project_dir: str, tasks: list[dict], args: dict, actions: list[dict]) -> dict {
    tid = str(args.get("id", "")).strip();
    if tid not in [t["id"] for t in tasks] { return {"ok": False, "text": f"failed: no task {tid}.\n" + list_text(tasks)}; }
    users = [t["id"] for t in tasks if tid in t["depends_on"]];
    if users { return {"ok": False, "text": f"failed: {', '.join(users)} depend on {tid}; drop them first."}; }
    tasks[:] = [t for t in tasks if t["id"] != tid];
    return {"ok": True, "text": f"dropped {tid}\n" + status_text(project_dir, tasks, actions)};
}

"""The names among `names` that a test block mentions."""
def named_in(body: str, names: list[str]) -> list[str] {
    return [n for n in names if re.search(r"\b" + re.escape(n) + r"\b", body)];
}

"""What still keeps the Tests phase from passing, as short lines; `required` are the functions to test.
Runs the suite only when everything else holds, since every test must fail while no body exists."""
def tests_problems(project_dir: str, required: list[str]) -> list[str] {
    blocks = test_blocks(project_dir);
    out: list[str] = [];
    if not blocks { return ["no test yet: write `test \"name\" { ... }` blocks in a .test.jac file"]; }
    out += [f"test \"{b['name']}\" is in {b['file']}; tests go in .test.jac files" for b in blocks if not b["file"].endswith(".test.jac")];
    named = [n for b in blocks for n in named_in(b["body"], required)];
    out += [f"`{n}` is called in no test" for n in required if n not in named];
    gave = [n for n in required if n not in missing_bodies(project_dir, required)];
    if gave { out.append(f"these have bodies now: {', '.join(gave)}; write no bodies in this phase, put the `;` back"); }
    if out { return out; }
    s = run_suite(project_dir);
    if not s["ran"] { return [not_ran_text(s, "no tests found")]; }
    out += [f"test \"{k}\" passes already; with no bodies written it tests nothing, so make it check what the description promises" for (k, v) in s["rows"].items() if v == "passed"];
    return out;
}

"""Which task's tests each test is: the first task in plan order after which every function it calls has a body.
`order` is [(task id, implements)] in plan order. Returns {task id: [test names]}."""
def assign_tests(project_dir: str, order: list[tuple]) -> dict {
    owner: dict = {};
    for (tid, impl) in order { for n in impl { owner.setdefault(n, tid); } }
    ids = [tid for (tid, impl) in order];
    out: dict = {tid: [] for tid in ids};
    if not ids { return out; }
    names = list(owner.keys());
    for b in test_blocks(project_dir) {
        at = [ids.index(owner[n]) for n in named_in(b["body"], names)];
        out[ids[max(at) if at else 0]].append(b["name"]);
    }
    return out;
}

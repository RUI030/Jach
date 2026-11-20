"""One walker = one session = one context (decisions 0005, 0007, 0010)."""
import os;
import from tree { Task, Step, Turn, Has, Then }
import from log { RunLog }
import from tools { READS, CHANGES, RUNS, PLANS, PHASE_TOOLS, schemas_for, run_tool }
import from planning { add_task, drop_task, plan_problems, status_text, tests_problems }
import from commands { run_suite }
import from check { jac_version, missing_bodies }
import from model { render, complete, parse_calls, is_repeating }
import from browse { run_actions }
import from knowledge { skill_list, reserved_text, section_text }

"""The system text the harness adds after the tool list the chat template renders."""
def system_text(version: str, phase: str = "task") -> str {
    goal = {"plan": "You plan a Jac web app with Jac {version}: declare what it needs, then cut the work into tasks. Write no bodies. "
                    + "Each task is later built in a fresh session that sees only its task card and the project files, so each task's goal and each declaration's description must be enough on their own.",
            "tests": "You write the unit tests of a Jac web app with Jac {version}, before any function body exists. "
                     + "The tests are frozen after this phase, and each task is built until its tests pass, so test what each description promises. "
                     + "The card says which functions to test and, under `Done when`, what submit checks.",
            "task": "You build one task of a Jac web app with Jac {version}. The task card says what to build and, under `Done when`, what submit checks."}[phase].replace("{version}", version);
    tools = PHASE_TOOLS[phase];
    changes = [t for t in (CHANGES + PLANS) if t in tools];
    runs = [t for t in RUNS if t in tools];
    return goal + "\n"
        + "You may make several tool calls in one reply; they run in order. "
        + f"A failed {' or '.join(changes)} stops the reply, and the calls after it are not run. "
        + f"{', '.join(runs)} " + ("each end" if len(runs) > 1 else "ends") + " a reply: no call after it runs.\n"
        + "Use list and read to see the project files. Fix the error shown first. When " + {"plan": "the plan", "tests": "the tests", "task": "the task"}[phase] + " is done, call submit.\n\n"
        + guide_text_for(version, TUNED) + "\n"
        + skill_list() + "\n"
        + f"What changed in this version: guide(topic=\"community/release_notes/jaclang\", section=\"jaclang {version}\"); "
        + "removed or renamed syntax: guide(topic=\"community/breaking-changes\").\n\n"
        + (pitfalls_text() + "\n\n" if not TUNED else "")
        + reserved_text() + ". This list comes from the installed compiler and wins over any guide.";
}

"""How the model should use the guides: a model trained on this Jac version reads them when it needs to;
a model that was not trained on it is asked to read before it writes (a request, never enforced)."""
def guide_text_for(version: str, tuned: bool) -> str {
    if tuned {
        return f"The guide tool reads the Jac {version} guides, the reference for this version. Read one when an error names it, or when you are not sure how this version writes something. Guides:";
    }
    return (f"You have not used Jac {version} before. It looks like Python and JSX but differs in many places. "
        + "Before you write your first .jac file, read guide(topic=\"jac-core-cheatsheet\"). Before you write a kind of code for the first time "
        + "(a client component, a server endpoint, a graph query), read the guide that covers it. Read the guide an error names. Guides:");
}

"""The Pitfalls section of the core cheatsheet, read from the installed guides; empty if this version has none."""
def pitfalls_text -> str {
    body = section_text("jac-core-cheatsheet", "Pitfalls");
    body = body[body.find("## Pitfalls"):] if "## Pitfalls" in body else body;
    return ("Common mistakes, from guide jac-core-cheatsheet:\n" + body.replace("## Pitfalls", "").strip()) if body else "";
}

glob TUNED = os.environ.get("JACH_TUNED", "0") == "1";  # setting: 1 for a model trained on this Jac version (JacLLM); 0 for Claude, GPT or an untrained base
glob MAX_FAILURES = 5;
glob MAX_TURNS = 40;
glob STEP_TOKENS = 32000;

"""One folded line for a turn (decision 0007 section 3)."""
def fold_line(t: dict) -> str {
    line = f"[{t['mid']}] {t['tool']} {t['target']}".rstrip() + f" -> {t['status']}";
    msg = t["message"];
    for word in ["failed: ", "refused: ", "not run: "] { if msg.startswith(word) { msg = msg[len(word):]; } }
    # A code that only repeats the status (not-run) or the tool's own category adds nothing.
    code = t["code"] if t["code"] not in ["not-run", "plan", "TEST"] else "";
    if t["status"] != "ok" and (code or msg) { line += f": {code} {msg}".replace("  ", " ").rstrip(); }
    return line;
}

walker Session {
    has server: str;
    has log: RunLog;
    has project_dir: str;
    has sid: str = "S1";
    has card: str = "";
    has turns: list[dict] = [];
    has n: int = 0;
    has outcome: str = "";
    has actions: list[dict] = [];
    has port: int = 8795;
    has dry: bool = False;
    has seen: list[str] = [];
    has system: str = "";
    has shown: list[dict] = [];
    has phase: str = "task";
    has intro: str = "";
    has implements: list[str] = [];
    has tasks: list[dict] = [];
    has tests: list[str] = [];  # tests submit runs in a task: the task's own and the finished tasks'
    has frozen: bool = False;  # .test.jac files were written in the Tests phase and cannot change

    """Build the messages for the next request. Each reply's calls are grouped; calls that did not
    succeed are folded to one line, except those of the newest reply."""
    def view -> list[dict] {
        msgs: list[dict] = [{"role": "system", "content": self.system}, {"role": "user", "content": self.card}];
        self.shown = [];
        groups: list[list[dict]] = [];
        for t in self.turns {
            if groups and groups[-1][0]["reply"] == t["reply"] { groups[-1].append(t); }
            else { groups.append([t]); }
        }
        for (gi, g) in enumerate(groups) {
            latest = gi == len(groups) - 1;
            full = [t for t in g if t["call"] and (latest or t["status"] == "ok")];
            rest = [t for t in g if not (t["call"] and (latest or t["status"] == "ok"))];
            if full {
                msgs.append({"role": "assistant", "content": "", "tool_calls": [{"type": "function", "function": {"name": t["tool"], "arguments": t["args"]}} for t in full]});
                for t in full { msgs.append({"role": "tool", "content": t["result"]}); }
            }
            if rest and latest {
                # Only a reply with no parsable call, or a cut-off last call, lands here.
                if not full { msgs.append({"role": "assistant", "content": rest[0]["raw"][:2000]}); }
                msgs.append({"role": "user", "content": "\n".join([t["result"] for t in rest])});
            } elif rest {
                msgs.append({"role": "user", "content": "\n".join([fold_line(t) for t in rest])});
            }
            self.shown += [{"id": t["mid"], "level": "full"} for t in full] + [{"id": t["mid"], "level": ("full" if latest else "line")} for t in rest];
        }
        return msgs;
    }

    """Run one parsed call and return the tool result."""
    def act(mid: str, call: dict) -> dict {
        tpath = str(call["args"].get("path", ""));
        allowed = PHASE_TOOLS[self.phase];
        if call["tool"] not in allowed {
            return {"status": "refused", "target": call["tool"], "code": "no-such-tool", "message": f"not available in {self.phase}",
                    "text": f"refused: no tool `{call['tool']}` here. Tools: {', '.join(allowed)}."};
        }
        # Only failures since the last file change count: after a change the same call can succeed.
        changed = [i for (i, p) in enumerate(self.turns) if p["status"] == "ok" and p["tool"] in CHANGES];
        since = self.turns[(changed[-1] + 1 if changed else 0):];
        dup = [p for p in since if p["status"] not in ["ok", "not-run"] and p["call"] and p["tool"] == call["tool"] and p["args"] == call["args"]];
        if dup {
            return {"status": "refused", "target": tpath, "code": "repeat",
                    "message": f"identical to {dup[-1]['mid']}, which failed",
                    "text": f"refused: this exact call already failed: {dup[-1]['code']} {dup[-1]['message']}. Change something first."};
        }
        # A whole-file write must not drop text the model never saw; an edit matches exact text, so it needs no read.
        if call["tool"] == "write" and tpath not in self.seen and os.path.isfile(os.path.join(self.project_dir, tpath)) {
            return {"status": "refused", "target": tpath, "code": "not-read", "message": "read the file first",
                    "text": f"refused: read {tpath} first."};
        }
        if self.frozen and call["tool"] in ["write", "edit"] and tpath.endswith(".test.jac") {
            return {"status": "refused", "target": tpath, "code": "frozen", "message": "tests are frozen",
                    "text": f"refused: {tpath} holds the tests written before the tasks; they cannot change. Change the code until they pass."};
        }
        if call["tool"] in PLANS {
            r = (add_task if call["tool"] == "add_task" else drop_task)(self.project_dir, self.tasks, call["args"], self.actions);
            return {"status": "ok" if r["ok"] else "failed", "target": str(call["args"].get("id", "")), "code": "" if r["ok"] else "plan",
                    "message": "" if r["ok"] else r["text"].split("\n")[0][:120], "text": r["text"]};
        }
        res = run_tool(self.project_dir, call["tool"], call["args"], self.port);
        if call["tool"] == "submit" and res["status"] == "ok" and self.phase == "plan" {
            probs = plan_problems(self.project_dir, self.tasks, self.actions);
            if probs {
                return {"status": "failed", "target": "plan", "code": "PLAN", "message": probs[0][:120],
                        "text": "check: clean, but the plan is not complete:\n" + "\n".join(["  " + p for p in probs]) + "\n" + status_text(self.project_dir, self.tasks, self.actions)};
            }
            return res;
        }
        if call["tool"] == "submit" and res["status"] == "ok" and self.phase == "tests" {
            probs = tests_problems(self.project_dir, self.implements);
            if probs {
                return {"status": "failed", "target": "tests", "code": "TESTS", "message": probs[0][:120],
                        "text": "check: clean, but the tests are not done:\n" + "\n".join(["  " + p for p in probs])};
            }
            return res;
        }
        if call["tool"] == "submit" and res["status"] == "ok" and self.implements and self.phase == "task" {
            bare = missing_bodies(self.project_dir, self.implements);
            if bare {
                return {"status": "failed", "target": "step", "code": "NO-BODY", "message": f"no body: {', '.join(bare)}",
                        "text": f"failed: still declared without a body: {', '.join(bare)}. Write each body in place of the `;`."};
            }
        }
        if call["tool"] in ["read", "write"] and res["status"] != "refused" and tpath not in self.seen { self.seen.append(tpath); }
        if call["tool"] == "submit" and res["status"] == "ok" and self.tests and self.phase == "task" {
            st = run_suite(self.project_dir);
            bad = [n for n in self.tests if st["rows"].get(n) != "passed"];
            if bad {
                why = st["fails"].get(bad[0], "") if st["ran"] else "the tests did not run:\n" + "\n".join(st["errors"]);
                return {"status": "failed", "target": "tests", "code": "TEST", "message": f'test "{bad[0]}" {st["rows"].get(bad[0], "did not run")}'[:200],
                        "text": f"failed: {len(bad)} of {len(self.tests)} tests do not pass: {', '.join(bad)}\nfirst failure ({bad[0]}):\n{why}"};
            }
        }
        if call["tool"] == "submit" and res["status"] == "ok" and self.actions and self.phase == "task" {
            for r in run_actions(self.project_dir, self.port, self.actions) {
                self.log.event("tool", "harness", {"tool": "browse", "target": r["name"], "status": r["status"], "message": r["message"], "result": r["text"]});
                if r["status"] != "ok" {
                    return {"status": "failed", "target": "step", "code": "BROWSER", "message": f'action "{r["name"]}": {r["message"]}'[:200],
                            "text": f'browser test "{r["name"]}" failed: {r["message"]}\n{r["text"]}'};
                }
            }
        }
        return res;
    }

    can open with Task entry {
        self.implements = here.implements;
        self.system = system_text(jac_version(), self.phase);
        # The card says what to do and when it is done; the files are read with tools.
        self.card = self.intro if self.intro else f"Task {here.tid}: {here.title}\nGoal: {here.goal}";
        self.seen = [];
        here.status = "active";
        self.log.at({"session": self.sid, "task": here.tid});
        self.log.event("task", "harness", {"status": "active", "card": self.card});
        visit [->:Has:->[?:Step]];
    }

    can work with Step entry {
        # One session works one step; steps of earlier attempts are already done.
        if here.status != "pending" { return; }
        here.status = "active";
        self.log.at({"step": here.kind});
        prev: Turn | None = None;
        while self.n < MAX_TURNS {
            msgs = self.view();
            prompt = render(self.server, msgs, schemas_for(PHASE_TOOLS[self.phase]));
            rseq = self.log.event("request", "harness", {"shown": self.shown, "prompt_chars": len(prompt)});
            self.log.prompt(rseq, prompt);
            retry = len(self.turns) > 0 and self.turns[-1]["status"] != "ok";
            out = complete(self.server, prompt, 4096, 0.7 if retry else 0.2, self.dry);
            self.n += 1;
            parsed = parse_calls(out["text"]);
            calls = parsed["calls"];
            error = parsed["error"];
            if not calls and is_repeating(out["text"]) { error = "the reply repeated itself until cut off. Write only what the task asks"; }
            elif not calls and out["truncated"] { error = "the reply was cut off. Write less in one reply"; }
            self.log.event("reply", "model", {"id": f"m{self.n}", "raw": out["text"], "calls": calls, "error": error, "prompt_tokens": out["prompt_tokens"], "out_tokens": out["out_tokens"]});
            # Calls run in order. A failed change stops the reply; nothing runs after a run call.
            batch: list[dict] = [];
            stop = "";
            for (k, call) in enumerate(calls) {
                mid = f"m{self.n}" if len(calls) == 1 and not error else f"m{self.n}.{k + 1}";
                if stop {
                    res = {"status": "not-run", "target": str(call["args"].get("path", "")), "code": "not-run", "message": stop,
                           "text": f"not run: {stop}."};
                } else {
                    res = self.act(mid, call);
                    if call["tool"] in CHANGES + PLANS and res["status"] != "ok" { stop = f"the {call['tool']} of {str(call['args'].get('path', call['args'].get('id', '')))} before it failed".replace(" of  ", " "); }
                    elif call["tool"] in RUNS { stop = f"{call['tool']} ends the reply"; }
                }
                t = {"mid": mid, "reply": self.n, "call": True, "tool": call["tool"], "args": call["args"], "raw": out["text"]};
                t.update({"target": res["target"], "status": res["status"], "code": res["code"], "message": res["message"], "result": res["text"]});
                self.turns.append(t);
                batch.append(t);
            }
            if error {
                mid = f"m{self.n}" if not calls else f"m{self.n}.{len(calls) + 1}";
                text = f"refused: {error}. Reply with tool calls." if not calls else f"refused: {error}; the calls before it ran, the calls after it did not.";
                t = {"mid": mid, "reply": self.n, "call": False, "tool": "(no call)", "args": {}, "raw": out["text"],
                     "target": "", "status": "refused", "code": "malformed", "message": error, "result": text};
                self.turns.append(t);
                batch.append(t);
            }
            for t in batch {
                self.log.event("tool", "harness", {"id": t["mid"], "tool": t["tool"], "args": t["args"], "status": t["status"], "code": t["code"], "message": t["message"], "result": t["result"]});
                node_t = Turn(mid=t["mid"], tool=t["tool"], target=t["target"], status=t["status"], code=t["code"], message=t["message"]);
                if prev is None { here +>:Has:+> node_t; } else { prev +>:Then:+> node_t; }
                prev = node_t;
                print(f"  {fold_line(t)}");
            }
            print(f"    [{out['prompt_tokens']} in, {out['out_tokens']} out]");

            reason = "";
            for t in batch {
                if t["status"] == "ok" {
                    if t["tool"] == "submit" { here.status = "passed"; self.outcome = "passed"; }
                    continue;
                }
                # A miss in the docs, or a failed check the model ran on its own (test, browse), is not a failed attempt at the task.
                if t["status"] == "not-run" or t["tool"] in ["guide", "guide_search", "test", "browse"] { continue; }
                here.failures += 1;
                if here.failures >= MAX_FAILURES { reason = "failures"; break; }
            }
            if self.outcome == "passed" { break; }
            if not reason and out["prompt_tokens"] >= STEP_TOKENS { reason = "step-tokens"; }
            if reason {
                here.status = "stalled";
                self.outcome = "stalled:" + reason;
                self.log.event("stall", "harness", {"rule": reason, "failures": here.failures, "id": batch[-1]["mid"] if batch else ""});
                break;
            }
        }
        if not self.outcome { here.status = "stalled"; self.outcome = "stalled:max-turns"; }
        self.log.event("step", "harness", {"status": here.status, "outcome": self.outcome, "turns": self.n, "failures": here.failures});
    }
}

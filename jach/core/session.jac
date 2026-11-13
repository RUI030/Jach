"""One walker = one session = one context (decisions 0005, 0007, 0010)."""
import os;
import from tree { Task, Step, Turn, Has, Then }
import from log { RunLog }
import from tools { SCHEMAS, run_tool }
import from model { render, complete, parse_call, is_repeating }
import from browse { run_actions }

glob SYSTEM = "You are building a Jac web app. Work only on the task you are given.\n"
    + "Call exactly one tool in each reply. After every write or edit the harness checks the file and shows the first error.\n"
    + "Fix the error shown before doing anything else. When the task is complete and the check is clean, call submit.";

glob MAX_FAILURES = 5;
glob SAME_ERROR = 3;
glob MAX_TURNS = 40;
glob STEP_TOKENS = 32000;

"""One folded line for a turn (decision 0007 section 3)."""
def fold_line(t: dict) -> str {
    line = f"[{t['mid']}] {t['tool']} {t['target']} -> {t['status']}";
    if t["status"] != "ok" and (t["code"] or t["message"]) { line += f": {t['code']} {t['message']}".rstrip(); }
    return line;
}

"""What the project holds now: the file list, and the text of the files this task may write (decision 8, first form)."""
def project_view(project_dir: str, writes: list[str]) -> str {
    names = sorted([f for f in os.listdir(project_dir) if os.path.isfile(os.path.join(project_dir, f))]);
    out = "The project was created from the template. Files: " + ", ".join(names) + "\nCurrent content of the files you may write:";
    for w in writes {
        full = os.path.join(project_dir, w);
        if not os.path.isfile(full) { out += f"\n\n--- {w} (does not exist yet)"; continue; }
        rows = open(full).read().rstrip("\n").split("\n");
        out += f"\n\n--- {w}\n" + "\n".join([f"{i + 1}│ {ln}" for (i, ln) in enumerate(rows)]);
    }
    return out;
}

walker Session {
    has server: str;
    has log: RunLog;
    has project_dir: str;
    has sid: str = "S1";
    has card: str = "";
    has writes: list[str] = [];
    has turns: list[dict] = [];
    has n: int = 0;
    has outcome: str = "";
    has actions: list[dict] = [];
    has port: int = 8795;
    has dry: bool = False;
    has guide: str = "";

    """Build the messages for the next request: failures folded, except the newest one."""
    def view -> list[dict] {
        msgs: list[dict] = [{"role": "system", "content": SYSTEM}, {"role": "user", "content": self.card}];
        last = len(self.turns) - 1;
        for (i, t) in enumerate(self.turns) {
            if t["status"] != "ok" and i != last {
                msgs.append({"role": "user", "content": fold_line(t)});
                continue;
            }
            if t["call"] {
                msgs.append({"role": "assistant", "content": "", "tool_calls": [{"type": "function", "function": {"name": t["tool"], "arguments": t["args"]}}]});
                msgs.append({"role": "tool", "content": t["result"]});
            } else {
                msgs.append({"role": "assistant", "content": t["raw"][:2000]});
                msgs.append({"role": "user", "content": t["result"]});
            }
        }
        return msgs;
    }

    can open with Task entry {
        self.writes = here.writes;
        self.card = f"Task {here.tid}: {here.title}\nGoal: {here.goal}\nYou may write: {', '.join(here.writes)}\n\n" + project_view(self.project_dir, here.writes);
        if self.guide { self.card += "\n\nReference for writing the page:\n" + self.guide; }
        here.status = "active";
        self.log.at({"session": self.sid, "task": here.tid});
        self.log.event("task", "harness", {"status": "active", "card": self.card});
        visit [->:Has:->[?:Step]];
    }

    can work with Step entry {
        self.log.at({"step": here.kind});
        prev: Turn | None = None;
        same = 0;
        last_err = "";
        while self.n < MAX_TURNS {
            msgs = self.view();
            prompt = render(self.server, msgs, SCHEMAS);
            shown = [{"id": t["mid"], "level": ("line" if (t["status"] != "ok" and i != len(self.turns) - 1) else "full")} for (i, t) in enumerate(self.turns)];
            rseq = self.log.event("request", "harness", {"shown": shown, "prompt_chars": len(prompt)});
            self.log.prompt(rseq, prompt);
            retry = len(self.turns) > 0 and self.turns[-1]["status"] != "ok";
            out = complete(self.server, prompt, 4096, 0.7 if retry else 0.2, self.dry);
            self.n += 1;
            mid = f"m{self.n}";
            call = parse_call(out["text"]);
            if not call["ok"] and is_repeating(out["text"]) {
                call = {"ok": False, "error": "the reply repeated the same lines over and over until it was cut off. Write a shorter file with only what the task asks for"};
            } elif not call["ok"] and out["truncated"] {
                call = {"ok": False, "error": "the reply was cut off at the output limit. Write less in one call"};
            }
            self.log.event("reply", "model", {"id": mid, "raw": out["text"], "call": call, "prompt_tokens": out["prompt_tokens"], "out_tokens": out["out_tokens"]});
            if call["ok"] {
                # Only failures since the last file change count: after a change the same call can succeed.
                changed = [i for (i, p) in enumerate(self.turns) if p["status"] == "ok" and p["tool"] in ["write", "edit"]];
                since = self.turns[(changed[-1] + 1 if changed else 0):];
                dup = [p for p in since if p["status"] != "ok" and p["call"] and p["tool"] == call["tool"] and p["args"] == call["args"]];
                if dup {
                    res = {"status": "refused", "target": str(call["args"].get("path", "")), "code": "repeat",
                           "message": f"identical to {dup[-1]['mid']}, which failed",
                           "text": f"refused: this call is identical to {dup[-1]['mid']}, which failed with: {dup[-1]['code']} {dup[-1]['message']}. Sending it again cannot work. Change the content."};
                } else {
                    res = run_tool(self.project_dir, self.writes, call["tool"], call["args"]);
                }
                if call["tool"] == "submit" and res["status"] == "ok" and self.actions {
                    for r in run_actions(self.project_dir, self.port, self.actions) {
                        self.log.event("tool", "harness", {"tool": "browse", "target": r["name"], "status": r["status"], "message": r["message"], "result": r["text"]});
                        if r["status"] != "ok" {
                            res = {"status": "failed", "target": "step", "code": "BROWSER", "message": f'action "{r["name"]}": {r["message"]}'[:200],
                                   "text": f'check: clean\nbrowser test failed in action "{r["name"]}": {r["message"]}\n{r["text"]}'};
                            break;
                        }
                    }
                }
                t = {"mid": mid, "call": True, "tool": call["tool"], "args": call["args"], "raw": out["text"]};
            } else {
                res = {"status": "refused", "target": "", "code": "malformed", "message": call["error"],
                       "text": f"refused: {call['error']}. Reply with exactly one complete tool call."};
                t = {"mid": mid, "call": False, "tool": "(no call)", "args": {}, "raw": out["text"]};
            }
            t.update({"target": res["target"], "status": res["status"], "code": res["code"], "message": res["message"], "result": res["text"]});
            self.turns.append(t);
            self.log.event("tool", "harness", {"id": mid, "tool": t["tool"], "args": t["args"], "status": t["status"], "code": t["code"], "message": t["message"], "result": t["result"]});
            node_t = Turn(mid=mid, tool=t["tool"], target=t["target"], status=t["status"], code=t["code"], message=t["message"]);
            if prev is None { here +>:Has:+> node_t; } else { prev +>:Then:+> node_t; }
            prev = node_t;
            print(f"  {fold_line(t)}   [{out['prompt_tokens']} in, {out['out_tokens']} out]");

            if t["status"] == "ok" {
                same = 0;
                last_err = "";
                if t["tool"] == "submit" { here.status = "passed"; self.outcome = "passed"; break; }
                continue;
            }
            here.failures += 1;
            err = t["code"] + "|" + t["message"];
            same = same + 1 if err == last_err else 1;
            last_err = err;
            reason = "";
            if same >= SAME_ERROR { reason = "same-error"; }
            elif here.failures >= MAX_FAILURES { reason = "failures"; }
            elif out["prompt_tokens"] >= STEP_TOKENS { reason = "step-tokens"; }
            if reason {
                here.status = "stalled";
                self.outcome = "stalled:" + reason;
                self.log.event("stall", "harness", {"rule": reason, "failures": here.failures});
                break;
            }
        }
        if not self.outcome { here.status = "stalled"; self.outcome = "stalled:max-turns"; }
        self.log.event("step", "harness", {"status": here.status, "outcome": self.outcome, "turns": self.n, "failures": here.failures});
    }
}

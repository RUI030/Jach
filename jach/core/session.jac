"""One walker = one session = one context (decisions 0005, 0007, 0010)."""
import from tree { Task, Step, Turn, Has, Then }
import from log { RunLog }
import from tools { SCHEMAS, run_tool }
import from model { render, complete, parse_call }

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
        self.card = f"Task {here.tid}: {here.title}\nGoal: {here.goal}\nYou may write: {', '.join(here.writes)}\nStart by reading the files you need.";
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
            out = complete(self.server, prompt, 4096);
            self.n += 1;
            mid = f"m{self.n}";
            call = parse_call(out["text"]) if not out["truncated"] else {"ok": False, "error": "the reply was cut off at the output limit"};
            self.log.event("reply", "model", {"id": mid, "raw": out["text"], "call": call, "prompt_tokens": out["prompt_tokens"], "out_tokens": out["out_tokens"]});
            if call["ok"] {
                res = run_tool(self.project_dir, self.writes, call["tool"], call["args"]);
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

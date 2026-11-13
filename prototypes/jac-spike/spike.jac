"""Spike: work tree as a graph, one walker = one session, raw llama-server calls."""
import json;
import time;
import from urllib.request { Request, urlopen }

glob URL = "http://127.0.0.1:8791";

node Project { has name: str; has brief: str = ""; }
node Feature { has title: str; }
node Task { has tid: str; has goal: str; has writes: list[str] = []; has status: str = "ready"; }
node Step { has kind: str; has status: str = "pending"; }
node Turn { has mid: str; has tool: str; has status: str; has prompt_tokens: int = 0; has out_tokens: int = 0; }
edge Has {}
edge Then {}

def post(path: str, body: dict) -> dict {
    req = Request(URL + path, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"});
    try { return json.loads(urlopen(req, timeout=120).read()); }
    except Exception as e { body = e.read().decode()[:300] if hasattr(e, "read") else str(e); print("HTTP ERROR:", body); raise e; }
}

def tools_for(kind: str) -> list[dict] {
    return [{"type": "function", "function": {"name": "write", "description": "Create or replace a file.",
        "parameters": {"type": "object", "properties": {"path": {"type": "string"}, "content": {"type": "string"}}, "required": ["path", "content"]}}}];
}

walker Session {
    has messages: list[dict] = [];
    has n: int = 0;
    has log: list[dict] = [];

    can open with Task entry {
        self.messages = [
            {"role": "system", "content": "You write Jac code. Use the tools. Task " + here.tid + ": " + here.goal + " You may write only: " + ", ".join(here.writes)},
            {"role": "user", "content": "Start the task."}
        ];
        here.status = "active";
        visit [->:Has:->[?:Step]];
    }

    can work with Step entry {
        if here.status == "passed" { return; }
        prev: Turn | None = None;
        for attempt in range(2) {
            t0 = time.perf_counter();
            r = post("/v1/chat/completions", {"messages": self.messages, "tools": tools_for(here.kind), "max_tokens": 3000, "temperature": 0.2});
            msg = r["choices"][0]["message"];
            calls = msg.get("tool_calls") or [];
            self.n += 1;
            ok = False;
            tool = "none";
            if calls {
                tool = calls[0]["function"]["name"];
                rawargs = calls[0]["function"]["arguments"];
                args: dict = {};
                try { args = json.loads(rawargs) if isinstance(rawargs, str) else rawargs; } except Exception as e { print("BAD ARGS finish=", r["choices"][0]["finish_reason"], "len=", len(rawargs), "tail=", repr(rawargs[-80:])); }
                ok = tool == "write" and args.get("path", "") != "";
            }
            turn = Turn(mid=f"m{self.n}", tool=tool, status="ok" if ok else "failed",
                        prompt_tokens=r["usage"]["prompt_tokens"], out_tokens=r["usage"]["completion_tokens"]);
            if prev is None { here +>:Has:+> turn; } else { prev +>:Then:+> turn; }
            prev = turn;
            self.log.append({"mid": turn.mid, "step": here.kind, "tool": tool, "status": turn.status,
                "prompt_tokens": turn.prompt_tokens, "out_tokens": turn.out_tokens, "sec": round(time.perf_counter() - t0, 2),
                "finish": r["choices"][0]["finish_reason"], "has_reasoning": bool(msg.get("reasoning_content"))});
            self.messages.append(msg);
            if ok {
                self.messages.append({"role": "tool", "tool_call_id": calls[0].get("id", ""), "content": "ok. check: clean"});
                here.status = "passed";
                break;
            }
            self.messages.append({"role": "user", "content": "Call the write tool."});
        }
    }
}

with entry {
    p = Project(name="todo");
    f = Feature(title="Task list");
    t = Task(tid="T01", goal="Define a node Task with fields title: str and done: bool = False.", writes=["tasks.jac"]);
    s = Step(kind="server");
    root +>:Has:+> p; p +>:Has:+> f; f +>:Has:+> t; t +>:Has:+> s;
    w = t spawn Session();
    for row in w.log { print(json.dumps(row)); }
    print("step:", s.status, "| task:", t.status, "| turns under step:", len([s ->:Has:->[?:Turn]]));
    print("last call args:", (w.messages[-2].get("tool_calls") or [{}])[0].get("function", {}).get("arguments", ""));
    raw = post("/apply-template", {"messages": w.messages[:2]});
    print("rendered prompt tail:", repr(raw["prompt"][-120:]));
}

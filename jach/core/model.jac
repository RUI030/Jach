"""The small model: exact prompt rendering, raw completion, our own tool-call parser (decision 0011)."""
import json;
import re;
import from urllib.request { Request, urlopen }

def post(url: str, body: dict) -> dict {
    req = Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"});
    return json.loads(urlopen(req, timeout=600).read());
}

"""Render messages and tools through the model's own chat template."""
def render(server: str, messages: list[dict], tools: list[dict]) -> str {
    return post(server + "/apply-template", {"messages": messages, "tools": tools})["prompt"];
}

def complete(server: str, prompt: str, max_tokens: int, temperature: float = 0.2, dry: bool = False) -> dict {
    body = {"prompt": prompt, "n_predict": max_tokens, "temperature": temperature, "cache_prompt": True, "stop": ["<|im_end|>"]};
    if dry { body.update({"dry_multiplier": 0.8, "dry_base": 1.75, "dry_allowed_length": 6, "dry_penalty_last_n": 2048}); }
    r = post(server + "/completion", body);
    return {"text": r.get("content", ""), "out_tokens": r.get("tokens_predicted", 0), "prompt_tokens": r.get("tokens_evaluated", 0),
            "truncated": bool(r.get("truncated", False)) or r.get("stop_type", "") == "limit"};
}

"""Parse one Qwen XML tool call. Never raises: a broken call comes back as ok=False with the reason."""
def parse_call(text: str) -> dict {
    body = text.split("</think>")[-1];
    m = re.search(r"<tool_call>\s*<function=([^>\s]+)>(.*?)</function>\s*</tool_call>", body, re.S);
    if not m {
        if "<tool_call>" in body { return {"ok": False, "error": "the tool call was cut off or not closed"}; }
        return {"ok": False, "error": "no tool call in the reply"};
    }
    args: dict = {};
    for p in re.finditer(r"<parameter=([^>\s]+)>\n?(.*?)\n?</parameter>", m.group(2), re.S) {
        args[p.group(1)] = p.group(2);
    }
    return {"ok": True, "tool": m.group(1), "args": args};
}

"""True when the text ends in the same block of lines repeated several times (a runaway)."""
def is_repeating(text: str) -> bool {
    lines = [ln for ln in text.split("\n") if ln.strip()];
    if len(lines) < 30 { return False; }
    for size in range(1, 13) {
        block = lines[-size:];
        reps = 1;
        while len(lines) >= size * (reps + 1) and lines[-size * (reps + 1):-size * reps] == block { reps += 1; }
        if reps >= 4 { return True; }
    }
    return False;
}

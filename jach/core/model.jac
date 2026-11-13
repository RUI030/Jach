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

def complete(server: str, prompt: str, max_tokens: int) -> dict {
    r = post(server + "/completion", {"prompt": prompt, "n_predict": max_tokens, "temperature": 0.2, "cache_prompt": True, "stop": ["<|im_end|>"]});
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

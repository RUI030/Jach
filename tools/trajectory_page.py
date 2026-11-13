"""Render one run's events.jsonl as a readable page: who said what, in order.

Usage: python3 tools/trajectory_page.py runs/<run> out.html
"""
import difflib
import html
import json
import sys

run_dir, out_path = sys.argv[1], sys.argv[2]
ev = [json.loads(line) for line in open(f"{run_dir}/events.jsonl")]
esc = html.escape


def pre(text):
    return f"<pre>{esc(text.rstrip())}</pre>"


def block(role, label, body, meta="", cls=""):
    m = f'<span class="meta">{esc(meta)}</span>' if meta else ""
    return f'<article class="msg {role} {cls}"><header><span class="who">{label}</span>{m}</header>{body}</article>'


def details(summary, body, is_open=False):
    return f'<details{" open" if is_open else ""}><summary>{esc(summary)}</summary>{body}</details>'


def diff_html(before, after, path):
    rows = []
    for line in difflib.unified_diff(before.splitlines(), after.splitlines(), lineterm="", n=2):
        if line.startswith(("+++", "---")):
            continue
        kind = "add" if line.startswith("+") else "del" if line.startswith("-") else "hunk" if line.startswith("@@") else "ctx"
        rows.append(f'<span class="{kind}">{esc(line) or " "}</span>')
    added = sum(1 for r in rows if 'class="add"' in r)
    removed = sum(1 for r in rows if 'class="del"' in r)
    return details(f"{path}: +{added} −{removed} lines", f'<pre class="diff">{chr(10).join(rows)}</pre>'), added, removed


spec = next(e for e in ev if e["type"] == "run" and "requirement" in e)
card = next(e for e in ev if e["type"] == "task")["card"]
replies = {e["id"]: e for e in ev if e["type"] == "reply" and e["actor"] == "model"}
tools = [e for e in ev if e["type"] == "tool" and e.get("id")]
last_id = tools[-1]["id"] if tools else ""
out = []

# The card: the Goal line is the user's request; the rest is computed by the harness.
head, _, rest = card.partition("\n\n")
lines = head.split("\n")
goal = next((ln for ln in lines if ln.startswith("Goal: ")), "")[6:]
others = "\n".join(ln for ln in lines if not ln.startswith("Goal: "))
out.append(block("system", "System prompt · written by the harness",
                 pre("You build a Jac web app. Do only the task. One tool call per reply.\n"
                     "Each write or edit is checked; fix the error shown first. When done, call submit.")
                 + '<p class="note">Sent with the definitions of four tools: read, write, edit, submit.</p>'))
out.append(block("user", "User request · the task spec", f"<p>{esc(goal)}</p>"))
out.append(block("harness", "Task card · computed by the harness from the project",
                 pre(others) + details("Files and their current content, as shown to the model", pre(rest))
                 + '<p class="note">The request and this card are sent together as one user message.</p>'))

for t in tools:
    mid, r = t["id"], replies[t["id"]]
    args = t.get("args") or {}
    meta = f'{mid} · {r.get("prompt_tokens", "?")} tokens in, {r.get("out_tokens", "?")} out'
    if t["tool"] == "(no call)":
        body = "<p>No tool call in the reply.</p>" + details("Raw output", pre(r["raw"][:3000]))
    else:
        call = f'<p class="call"><b>{esc(t["tool"])}</b> {esc(str(args.get("path", "")))}</p>'
        if t["tool"] == "write":
            call += details(f'content ({len(args.get("content", "").splitlines())} lines)', pre(args.get("content", "")))
        elif t["tool"] == "edit":
            call += details("old → new", '<div class="pair">' + pre(args.get("old", "")) + pre(args.get("new", "")) + "</div>")
        body = call
    out.append(block("model", "Small model · tool call", body, meta))

    status = t["status"]
    is_gate = t["tool"] == "submit"
    label = "Harness · gate (check, wiring, browser)" if is_gate else "Harness · tool result"
    body = pre(t["result"][:2500])
    if status != "ok" and mid != last_id:
        code = (t.get("code", "") + " " + t.get("message", "")).strip()
        folded = f'[{mid}] {t["tool"]} {t.get("target") or args.get("path", "")} -> {status}' + (f": {code}" if code else "")
        body += f'<p class="fold">From the next turn on, the model sees this turn as one line:</p>{pre(folded)}'
    out.append(block("harness", label, body, status, status))

for e in ev:
    if e["type"] == "stall":
        out.append(block("stall", "Harness · stall rule", f'<p>Rule <b>{esc(e["rule"])}</b> fired after {e.get("failures", "?")} failed or refused calls. The step goes to the admin.</p>'))

attempt_files = {}
for e in ev:
    if e["type"] == "file" and e.get("note") == "before admin":
        attempt_files.setdefault(e["attempt"], {"before": {}, "after": {}})["before"][e["path"]] = e["content"]
attempt = 0
for e in ev:
    if e["type"] == "request" and e["actor"] == "admin":
        attempt = e["attempt"]
        out.append(block("harness", f"Harness · request to the admin, attempt {attempt}",
                         details("Prompt (task, failing check, rules)", pre(e["prompt"]))))
    elif e["type"] == "file" and e["actor"] == "admin":
        attempt_files[attempt]["after"][e["path"]] = e["content"]
    elif e["type"] == "reply" and e["actor"] == "admin":
        attempt_files[attempt]["said"] = (e["raw"], e.get("sec"))
    elif e["type"] == "tool" and e.get("after") == "admin":
        a = attempt_files[attempt]
        parts, plus, minus = [], 0, 0
        for path, text in a["after"].items():
            h, p, m = diff_html(a["before"].get(path, ""), text, path)
            parts.append(h); plus += p; minus += m
        said, sec = a.get("said", ("", None))
        out.append(block("admin", f"Admin (Codex) · attempt {attempt}",
                         f"<p>{esc(said)}</p>" + "".join(parts) + '<p class="note">Only the files it changed are logged, not its own steps.</p>',
                         f"+{plus} −{minus} lines · {sec} s"))
        out.append(block("harness", "Harness · gate on the admin's work", pre(e["result"][:1800]), e["status"], e["status"]))

final = [e for e in ev if e["type"] == "tool" and e["tool"] == "browse" and not e.get("id")]
if final:
    body = "".join(f'<p class="call"><b>{esc(e["target"])}</b> · {e["status"]}</p>{pre(e["result"][:1200])}' for e in final)
    ok = all(e["status"] == "ok" for e in final)
    out.append(block("harness", "Harness · final browser test on a fresh copy", body, "ok" if ok else "failed", "ok" if ok else "failed"))

n_model = len(tools)
n_bad = sum(1 for t in tools if t["status"] != "ok")
outcome = [e for e in ev if e["type"] == "run" and "outcome" in e][-1]["outcome"]
title = card.split("\n")[0].split(": ", 1)[-1]
page = f"""<title>Trajectory: {esc(title)}</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
/* Layout: one column, one message per block, in the order they happened; the label on each block says who wrote it. */
:root{{--bg:#f3f1ee;--paper:#fff;--ink:#16181c;--muted:#5d6269;--line:#dedbd6;--code:#f5f4f1;
 --model:#e8542a;--model-bg:#fdf1ec;--user:#1b7fb0;--user-bg:#eaf4fa;--harness:#4a5261;--admin:#6b3fa0;--admin-bg:#f3edfa;
 --ok:#1d6b3a;--ok-bg:#e6f3ea;--bad:#a8321c;--bad-bg:#fbe9e6;
 --sans:"Inter",system-ui,-apple-system,"Segoe UI",Arial,sans-serif;--mono:"JetBrains Mono",ui-monospace,Menlo,Consolas,monospace}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#15161a;--paper:#1d1f24;--ink:#e9e7e3;--muted:#a0a4ab;--line:#33363d;--code:#26282e;
 --model:#ff8a63;--model-bg:#2e211c;--user:#6bbde6;--user-bg:#1a2831;--harness:#b3bac6;--admin:#c3a1f0;--admin-bg:#27203a;
 --ok:#7dcf9a;--ok-bg:#1b2c22;--bad:#f09a88;--bad-bg:#33201c;color-scheme:dark}}}}
:root[data-theme="dark"]{{--bg:#15161a;--paper:#1d1f24;--ink:#e9e7e3;--muted:#a0a4ab;--line:#33363d;--code:#26282e;
 --model:#ff8a63;--model-bg:#2e211c;--user:#6bbde6;--user-bg:#1a2831;--harness:#b3bac6;--admin:#c3a1f0;--admin-bg:#27203a;
 --ok:#7dcf9a;--ok-bg:#1b2c22;--bad:#f09a88;--bad-bg:#33201c;color-scheme:dark}}
body{{background:var(--bg);color:var(--ink);font-family:var(--sans);font-size:15px;line-height:1.5;padding-block:28px;
 padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}}
main{{max-width:900px;margin:0 auto;display:flex;flex-direction:column;gap:12px}}
.kick{{color:var(--model);font-weight:600;font-size:13px}}
h1{{font-size:28px;line-height:1.15;margin:0;letter-spacing:-.01em;text-wrap:balance}}
.lead{{margin:0;max-width:65ch}}
.facts{{display:flex;flex-wrap:wrap;gap:6px 22px;font-size:13px;color:var(--muted);font-variant-numeric:tabular-nums}}
.facts b{{color:var(--ink)}}
.legend{{display:flex;flex-wrap:wrap;gap:8px;font-size:12px;margin-block:6px}}
.legend span{{padding:2px 9px;border-radius:99px;font-weight:600}}
.msg{{background:var(--paper);border:1px solid var(--line);border-radius:10px;padding:12px 14px;display:flex;flex-direction:column;gap:8px;min-width:0}}
.msg header{{display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;align-items:baseline}}
.who{{font-weight:700;font-size:13px}}
.meta{{font-size:12px;color:var(--muted);font-variant-numeric:tabular-nums}}
.msg p{{margin:0}}
.model{{background:var(--model-bg);margin-left:clamp(0px,6vw,56px)}} .model .who,.l-model{{color:var(--model)}}
.user{{background:var(--user-bg)}} .user .who,.l-user{{color:var(--user)}}
.harness .who,.system .who,.l-harness{{color:var(--harness)}}
.admin{{background:var(--admin-bg);margin-left:clamp(0px,6vw,56px)}} .admin .who,.l-admin{{color:var(--admin)}}
.stall{{background:var(--bad-bg)}} .stall .who{{color:var(--bad)}}
.l-model{{background:var(--model-bg)}} .l-user{{background:var(--user-bg)}} .l-harness{{background:var(--code)}} .l-admin{{background:var(--admin-bg)}}
.msg.ok .meta{{color:var(--ok);font-weight:700}} .msg.failed .meta,.msg.refused .meta{{color:var(--bad);font-weight:700}}
pre,code{{font-family:var(--mono);font-variant-ligatures:none}}
pre{{margin:0;background:var(--code);border-radius:6px;padding:9px 11px;font-size:12.5px;line-height:1.45;overflow-x:auto;white-space:pre}}
.call{{font-family:var(--mono);font-size:13.5px}}
.note,.fold{{font-size:12.5px;color:var(--muted)}}
details summary{{cursor:pointer;font-size:13px;color:var(--muted);padding-block:2px}}
details summary:focus-visible{{outline:2px solid var(--user);outline-offset:2px}}
details[open] summary{{margin-bottom:6px}}
.pair{{display:grid;grid-template-columns:1fr;gap:6px}} .pair pre{{min-width:0}}
@media (min-width:760px){{.pair{{grid-template-columns:1fr 1fr}}}}
.diff span{{display:block}} .diff .add{{background:var(--ok-bg);color:var(--ok)}} .diff .del{{background:var(--bad-bg);color:var(--bad)}} .diff .hunk{{color:var(--muted)}}
</style>
<main>
<div class="kick">New Harness · one run, start to finish</div>
<h1>Trajectory: {esc(title)}</h1>
<p class="lead">Every message of one run, in order. The label on each block says who wrote it. Long content is folded; click to open.</p>
<div class="facts"><span>Small model <b>JacLLM v1.35</b></span><span>Model turns <b>{n_model}</b></span><span>Failed or refused <b>{n_bad}</b></span><span>Admin attempts <b>{max(attempt_files) if attempt_files else 0}</b></span><span>Outcome <b>{esc(outcome)}</b></span></div>
<div class="legend"><span class="l-user">User request</span><span class="l-harness">Harness</span><span class="l-model">Small model</span><span class="l-admin">Admin</span></div>
{chr(10).join(out)}
</main>
"""
open(out_path, "w").write(page)
print(len(page), "bytes", n_model, "turns")

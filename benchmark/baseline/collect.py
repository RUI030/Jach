"""Collect every baseline run under OUT_ROOT into runs.json and a summary table: collect.py <out root>.

A run is a directory <model>/<arm>-<task>-r<round>/ written by run.sh. Writes <out root>/runs.json (one row per run)
and <out root>/summary.md (pass counts per model, arm and difficulty, then per task).
"""
import glob
import json
import os
import re
import sys

ROOT = sys.argv[1]
NONJAC_CMD = re.compile(r'\b(npm|npx|pip3?|yarn|pnpm|uvicorn|flask|vite|create-react-app)\b|\bnode\s+\S+\.js|\bpython3?\s+\S+\.py')
NONJAC_CODE = re.compile(r'import\s+from\s+["\']?(react|react-dom)\b|\buseState\b|\buseEffect\b|::py::|localStorage|\baxios\b')


def read(path, default=''):
    return open(path, errors='ignore').read() if os.path.exists(path) else default


def agent_stats(run):
    """Tool calls from pi's event stream; turns, output tokens and largest prompt from its session file."""
    tools, cmds, skills = {}, [], set()
    for line in read(os.path.join(run, 'agent.jsonl')).splitlines():
        try:
            x = json.loads(line)
        except ValueError:
            continue
        if x.get('type') == 'tool_execution_start':
            t, a = x.get('toolName'), x.get('args') or {}
            tools[t] = tools.get(t, 0) + 1
            skills.update(re.findall(r'skills/(jac-[a-z-]+)', json.dumps(a)))
            if t == 'bash':
                cmds.append(a.get('command', ''))
    turns = out_tok = max_ctx = 0
    for p in glob.glob(os.path.join(run, 'session', '*.jsonl')):
        for line in open(p, errors='ignore'):
            try:
                x = json.loads(line)
            except ValueError:
                continue
            u = (x.get('message') or {}).get('usage') if isinstance(x.get('message'), dict) else None
            if isinstance(u, dict):
                turns += 1
                out_tok += u.get('output', 0) or 0
                max_ctx = max(max_ctx, (u.get('input', 0) or 0) + (u.get('cacheRead', 0) or 0))
    return tools, cmds, sorted(skills), turns, out_tok, max_ctx


rows = []
for run in sorted(glob.glob(os.path.join(ROOT, '*', '*-r[0-9]*'))):
    if not os.path.exists(os.path.join(run, 'meta.json')):
        continue
    r = json.load(open(os.path.join(run, 'meta.json')))
    r['dir'] = os.path.relpath(run, ROOT)
    gate = json.loads(read(os.path.join(run, 'gate.json')) or '{}')
    ex = dict(ln.strip().split('=', 1) for ln in read(os.path.join(run, 'exit.txt')).splitlines() if '=' in ln)
    acts = gate.get('actions', [])
    r['exit'] = {'0': 'finished', '124': 'timeout'}.get(ex.get('exit', ''), 'exit ' + ex.get('exit', '?'))
    r['seconds'] = int(ex.get('seconds', 0))
    r['checks'] = gate.get('checks', {})
    r['actions'] = acts
    r['started'] = bool(acts) and not any('did not start' in a.get('message', '') for a in acts)
    r['actions_passed'] = sum(a['status'] == 'ok' for a in acts)
    r['actions_total'] = len(acts)
    r['kept_after_restart'] = bool(acts) and acts[-1]['status'] == 'ok'
    r['passed'] = gate.get('browser') == 'passed'
    tools, cmds, skills, r['turns'], r['output_tokens'], r['max_context'] = agent_stats(run)
    r['tools'], r['skills_read'] = tools, skills
    files = [ln.strip()[2:] for ln in read(os.path.join(run, 'files.txt')).splitlines()]
    r['files'] = files
    if r['arm'] == 'any':
        exts = {}
        for f in files:
            e = os.path.splitext(f)[1] or f
            exts[e] = exts.get(e, 0) + 1
        r['stack'] = exts
    else:
        r['nonjac_cmds'] = [c[:200] for c in cmds if NONJAC_CMD.search(c)][:5]
        r['nonjac_files'] = [f for f in files if not f.endswith(('.jac', '.toml', '.jab', '.css', '.md'))
                             and not os.path.basename(f).startswith('.')]
        flags = set()
        for f in files:
            if f.endswith('.jac'):
                code = '\n'.join(re.sub(r'#.*$', '', ln) for ln in read(os.path.join(run, 'project', f)).splitlines())
                flags.update(f'{f}: {m.group(0)}' for m in NONJAC_CODE.finditer(code))
        r['nonjac_code'] = sorted(flags)
    r['shots'] = sorted(os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(run, 'shots', '*.png')))
    rows.append(r)

json.dump(rows, open(os.path.join(ROOT, 'runs.json'), 'w'), indent=1)

# Summary: per model x arm, tasks passed by difficulty; then per task, passes out of rounds.
out = ['# Baseline summary', '', '| Model | Arm | Easy passed | Hard passed | All | Actions passed | Median seconds |', '|---|---|---|---|---|---|---|']
groups = sorted({(r['model'], r['arm']) for r in rows})
for (m, a) in groups:
    g = [r for r in rows if r['model'] == m and r['arm'] == a]
    e = [r for r in g if r['difficulty'] == 'easy']
    h = [r for r in g if r['difficulty'] == 'hard']
    secs = sorted(r['seconds'] for r in g)
    out.append(f"| {m} | {a} | {sum(r['passed'] for r in e)}/{len(e)} | {sum(r['passed'] for r in h)}/{len(h)} | "
               f"{sum(r['passed'] for r in g)}/{len(g)} | {sum(r['actions_passed'] for r in g)}/{sum(r['actions_total'] for r in g)} | "
               f"{secs[len(secs) // 2] if secs else 0} |")
tasks = sorted({(r['level'], r['task']) for r in rows})
out += ['', '| Task | ' + ' | '.join(f'{m} {a}' for (m, a) in groups) + ' |', '|---|' + '---|' * len(groups)]
for (lvl, t) in tasks:
    cells = []
    for (m, a) in groups:
        g = [r for r in rows if r['model'] == m and r['arm'] == a and r['task'] == t]
        cells.append(f"{sum(r['passed'] for r in g)}/{len(g)}" if g else '-')
    out.append(f'| {t} | ' + ' | '.join(cells) + ' |')
open(os.path.join(ROOT, 'summary.md'), 'w').write('\n'.join(out) + '\n')
print(len(rows), 'runs ->', os.path.join(ROOT, 'runs.json'), os.path.join(ROOT, 'summary.md'))

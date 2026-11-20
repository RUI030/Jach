"""Watch one pi session for being stuck: watch.py <agent.jsonl> <byte offset> <pid>

Reads pi's --mode json events appended to agent.jsonl after <offset> while <pid> (the session's process) runs.
When the session is stuck it kills <pid> and everything under it, prints the reason on stdout and exits 1;
when <pid> ends on its own it prints nothing and exits 0. Stuck means any of:
  hung_tool   one tool call has run for more than HUNG s (e.g. a server started in the foreground)
  silent      no event at all for more than SILENT s
  repeat      the same tool call (name and arguments) 4 or more times in the last 8 calls
  length      two assistant turns in a row ended at the output-token limit (a thinking loop)
"""
import json, os, signal, sys, time

HUNG, SILENT, POLL = (int(os.environ.get(k, d)) for k, d in (("WATCH_HUNG", 300), ("WATCH_SILENT", 300), ("WATCH_POLL", 5)))
path, offset, pid = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])


def alive(p):
    try:
        os.kill(p, 0)
        return not open(f'/proc/{p}/stat').read().split(')')[-1].split()[0] == 'Z'
    except (OSError, IndexError):
        return False


def tree(p):
    out = [p]
    for t in os.listdir(f'/proc/{p}/task') if os.path.isdir(f'/proc/{p}/task') else []:
        try:
            for c in open(f'/proc/{p}/task/{t}/children').read().split():
                out += tree(int(c))
        except OSError:
            pass
    return out


def kill_tree(p):
    pids = tree(p)
    for sig in (signal.SIGTERM, signal.SIGKILL):
        for q in reversed(pids):
            try:
                os.kill(q, sig)
            except OSError:
                pass
        time.sleep(3)


pos, buf = offset, ''
open_tools, calls, lengths = {}, [], 0
last_event = time.time()
while alive(pid):
    try:
        with open(path) as f:
            f.seek(pos)
            chunk = f.read()
            pos = f.tell()
    except OSError:
        chunk = ''
    now = time.time()
    if chunk:
        last_event = now
    buf += chunk
    *lines, buf = buf.split('\n')
    for ln in lines:
        try:
            x = json.loads(ln)
        except ValueError:
            continue
        t = x.get('type')
        if t == 'tool_execution_start':
            open_tools[x.get('toolCallId')] = now
            calls.append((x.get('toolName'), json.dumps(x.get('args'), sort_keys=True)))
        elif t == 'tool_execution_end':
            open_tools.pop(x.get('toolCallId'), None)
        elif t == 'message_end' and (x.get('message') or {}).get('role') == 'assistant':
            lengths = lengths + 1 if (x['message'].get('stopReason') == 'length') else 0
    reason = ''
    if open_tools and now - min(open_tools.values()) > HUNG:
        reason = 'hung_tool'
    elif now - last_event > SILENT:
        reason = 'silent'
    elif calls and max(calls[-8:].count(c) for c in calls[-8:]) >= 4:
        reason = 'repeat'
    elif lengths >= 2:
        reason = 'length'
    if reason:
        kill_tree(pid)
        print(reason)
        sys.exit(1)
    time.sleep(POLL)

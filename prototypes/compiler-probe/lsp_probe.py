"""Drive `jac lsp` over stdio: open a file, edit it, time diagnostics; try documentSymbol."""
import json, subprocess, sys, time, os, threading, queue

path = os.path.abspath(sys.argv[1])
uri = "file://" + path
p = subprocess.Popen(["jac", "lsp"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, cwd=os.path.dirname(path))
q = queue.Queue()

def reader():
    f = p.stdout
    while True:
        hdr = b""
        while not hdr.endswith(b"\r\n\r\n"):
            c = f.read(1)
            if not c:
                return
            hdr += c
        n = int([l for l in hdr.decode().split("\r\n") if l.lower().startswith("content-length")][0].split(":")[1])
        q.put(json.loads(f.read(n)))
threading.Thread(target=reader, daemon=True).start()

def send(m):
    b = json.dumps(m).encode()
    p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(b) + b); p.stdin.flush()

def wait(pred, timeout=30):
    end = time.time() + timeout
    while time.time() < end:
        try:
            m = q.get(timeout=end - time.time())
        except queue.Empty:
            break
        if pred(m):
            return m
    return None

t0 = time.time()
send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"processId": None, "rootUri": "file://" + os.path.dirname(path), "capabilities": {}}})
r = wait(lambda m: m.get("id") == 1)
caps = r["result"]["capabilities"]
print(f"initialize: {time.time()-t0:.2f}s; capabilities: {sorted(caps.keys())}")
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
src = open(path).read()
t0 = time.time()
send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {"uri": uri, "languageId": "jac", "version": 1, "text": src}}})
d = wait(lambda m: m.get("method") == "textDocument/publishDiagnostics" and m["params"]["uri"] == uri)
print(f"didOpen -> diagnostics: {time.time()-t0:.2f}s, n={len(d['params']['diagnostics']) if d else None}")
for v in range(2, 6):
    bad = src + f"\nwith entry {{ x{v}: int = \"s\"; }}\n"
    t0 = time.time()
    send({"jsonrpc": "2.0", "method": "textDocument/didChange", "params": {"textDocument": {"uri": uri, "version": v}, "contentChanges": [{"text": bad}]}})
    d = wait(lambda m: m.get("method") == "textDocument/publishDiagnostics" and m["params"]["uri"] == uri and len(m["params"]["diagnostics"]) > 0)
    print(f"didChange v{v} -> diagnostics: {time.time()-t0:.2f}s, first={d['params']['diagnostics'][0] if d else None}")
t0 = time.time()
send({"jsonrpc": "2.0", "id": 9, "method": "textDocument/documentSymbol", "params": {"textDocument": {"uri": uri}}})
r = wait(lambda m: m.get("id") == 9)
print(f"documentSymbol: {time.time()-t0:.2f}s -> {json.dumps(r.get('result'))[:600] if r else None}")
p.kill()

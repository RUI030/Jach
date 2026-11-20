#!/usr/bin/env bash
# One baseline run with the pi harness: run.sh <arm: any|jac> <task id> <round>
#
#   any: empty folder, any stack, no skills, no MCP; spec jach/tasks/any/<task>.json; the app starts with `sh start.sh`.
#   jac: jach/template, the Jac skills in tools/baseline/skills; spec jach/tasks/<task>.json; the app starts with `jac start`.
#
# Environment (defaults in brackets):
#   MODEL_ID [ornith-1.5-9b]   the model alias the OpenAI-compatible server serves (llama-server --alias)
#   BASE_URL [http://127.0.0.1:8791/v1]
#   CTX [65536]  MAXTOK [16384]  THINKING [medium]  TIMEOUT [1800] seconds for the agent
#   JAC_MCP [0]                1 also gives the jac arm the `jac mcp` server
#   OUT_ROOT [$REPO/runs/baseline]   WORK [~/.cache/jbw]   GATE_PORT [8795]
#
# Writes $OUT_ROOT/<MODEL_ID>/<arm>-<task>-r<round>/: meta.json, prompt.txt, agent.jsonl, agent.err, session/,
# exit.txt, files.txt, project/, gate.json, shots/ (00-load.png, then one png per action as it ended).
set -u
ARM=$1; TASK=$2; ROUND=$3
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
MODEL_ID=${MODEL_ID:-ornith-1.5-9b}
BASE_URL=${BASE_URL:-http://127.0.0.1:8791/v1}
CTX=${CTX:-65536}; MAXTOK=${MAXTOK:-16384}; THINKING=${THINKING:-medium}; TIMEOUT=${TIMEOUT:-1800}
JAC_MCP=${JAC_MCP:-0}
OUT_ROOT=${OUT_ROOT:-$REPO/runs/baseline}
WORK=${WORK:-$HOME/.cache/jbw}
GATE_PORT=${GATE_PORT:-8795}

case $ARM in
  any) SPECF=$REPO/jach/tasks/any/$TASK.json ;;
  jac) SPECF=$REPO/jach/tasks/$TASK.json ;;
  *) echo "arm must be any or jac" >&2; exit 2 ;;
esac
[ -f "$SPECF" ] || { echo "no spec $SPECF" >&2; exit 2; }

NAME=$ARM-$TASK-r$ROUND
OUT=$OUT_ROOT/$MODEL_ID/$NAME
P=$WORK/$MODEL_ID/$NAME/project
rm -rf "$OUT" "$WORK/$MODEL_ID/$NAME"; mkdir -p "$OUT" "$P"

# pi config for this model: one provider "local" with one model; skills are passed per arm on the command line.
AGENT_DIR=$OUT_ROOT/$MODEL_ID/pi-agent
mkdir -p "$AGENT_DIR"
cat > "$AGENT_DIR/models.json" <<EOF
{"providers": {"local": {"baseUrl": "$BASE_URL", "api": "openai-completions", "apiKey": "none",
  "models": [{"id": "$MODEL_ID", "reasoning": true, "contextWindow": $CTX, "maxTokens": $MAXTOK}]}}}
EOF
echo '{"theme":"dark","quietStartup":true}' > "$AGENT_DIR/settings.json"
echo '{"mcpServers": {"jac": {"command": "jac", "args": ["mcp"], "exposure": "direct"}}}' > "$AGENT_DIR/mcp.json"

GOAL=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['goal'])" "$SPECF")
if [ "$ARM" = any ]; then
  PROMPT="$GOAL

The current folder is empty. Use any language, framework and packages you like. When you finish, this folder must contain \`start.sh\`: running \`sh start.sh\` starts the app on the port in the environment variable PORT (8000 if PORT is unset) and serves the page at /. Install every dependency before you finish; start.sh only starts the app."
  EXTRA=(--no-skills --no-mcp)
else
  # Same start as the jach harness (cli.jac): the installed Jac's jac-shadcn scaffold, AGENTS.md removed,
  # `.jach-scaffold` listing the scaffold's files, our three template files on top. The scaffold is made once and copied.
  SCAF=$WORK/_scaffold/project
  if [ ! -f "$SCAF/.jach-scaffold" ]; then
    rm -rf "$WORK/_scaffold"; mkdir -p "$WORK/_scaffold"
    (cd "$WORK/_scaffold" && timeout 600 jac create project --use jac-shadcn > create.log 2>&1) || { echo "jac create failed: $WORK/_scaffold/create.log" >&2; exit 1; }
    rm -f "$SCAF/AGENTS.md"
    python3 - "$SCAF" <<'EOF'
import os, sys
root, ours, found = sys.argv[1], ["main.jac", "server.jac", "frontend.jac"], []
for base, dirs, files in os.walk(root):
    dirs[:] = sorted(d for d in dirs if not d.startswith(".") and d not in ["node_modules", "dist", "build", "__pycache__"])
    found += [os.path.relpath(os.path.join(base, f), root) for f in sorted(files) if not f.startswith(".")]
open(os.path.join(root, ".jach-scaffold"), "w").write("\n".join(p for p in found if p not in ours))
EOF
  fi
  cp -a "$SCAF/." "$P"
  for f in main.jac server.jac frontend.jac; do cp "$REPO/jach/template/$f" "$P/$f"; done
  PROMPT="This directory is a Jac web app (Jac 0.36.1). It is served with \`jac start main.jac\`.

$GOAL

You may change server.jac, frontend.jac and main.jac."
  EXTRA=(--no-skills --skill "$HERE/skills")
  [ "$JAC_MCP" = 1 ] || EXTRA+=(--no-mcp)
fi
echo "$PROMPT" > "$OUT/prompt.txt"
python3 - "$SPECF" "$OUT/meta.json" "$ARM" "$MODEL_ID" "$ROUND" "$THINKING" "$CTX" "$TIMEOUT" "$JAC_MCP" <<'EOF'
import json, sys
s = json.load(open(sys.argv[1]))
json.dump({"arm": sys.argv[3], "model": sys.argv[4], "task": s["id"].removesuffix("-any"), "round": int(sys.argv[5]),
           "level": s["level"], "difficulty": s["difficulty"], "harness": "pi", "thinking": sys.argv[6],
           "ctx": int(sys.argv[7]), "timeout": int(sys.argv[8]), "jac_mcp": sys.argv[9] == "1"}, open(sys.argv[2], "w"), indent=1)
EOF

START=$(date +%s)
(cd "$P" && PI_CODING_AGENT_DIR=$AGENT_DIR PI_OFFLINE=1 \
  timeout "$TIMEOUT" bwrap --dev-bind / / --unshare-pid --proc /proc --die-with-parent \
  pi -p --model "local/$MODEL_ID" --thinking "$THINKING" "${EXTRA[@]}" --no-context-files \
  --session-dir "$OUT/session" --mode json < "$OUT/prompt.txt" > "$OUT/agent.jsonl" 2> "$OUT/agent.err")
echo "exit=$?" > "$OUT/exit.txt"
echo "seconds=$(( $(date +%s) - START ))" >> "$OUT/exit.txt"

# Servers the agent left running in its project.
for pid in $(pgrep -f "jac (start|serve)|node|python|start.sh"); do
  case "$(readlink /proc/$pid/cwd 2>/dev/null)" in "$WORK/$MODEL_ID/$NAME"*) kill "$pid" 2>/dev/null;; esac
done

(cd "$P" && find . -type f -not -path './.jac/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' \
  -not -path '*/__pycache__/*' -not -name '.jach-server.log' | sort) > "$OUT/files.txt"
cp -r "$P" "$OUT/project"
rm -rf "$OUT/project/.jac"; find "$OUT/project" \( -name node_modules -o -name .venv \) -prune -exec rm -rf {} +

GATE_ARGS=("$P" "$SPECF" "$GATE_PORT"); [ "$ARM" = any ] && GATE_ARGS+=(any)
(cd "$REPO" && JACH_SHOTS=$OUT/shots timeout 900 jac run jach/core/gate.jac "${GATE_ARGS[@]}" 2>/dev/null \
  | grep '^GATE ' | sed 's/^GATE //' > "$OUT/gate.json")
echo "$MODEL_ID/$NAME $(cat "$OUT/gate.json") $(tr '\n' ' ' < "$OUT/exit.txt")"

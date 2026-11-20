#!/usr/bin/env bash
# Create one fresh, git-tracked project per arm for an A/B app-build test.
#
#   ./init.sh <SPEC> [APP]      e.g. ./init.sh PaperJac
#
# Reads spec/<SPEC>/{spec.md,papers.json}; writes Impl/<ARM>/<APP>/ for each arm with
#   - the arm's scaffold (dependencies installed),
#   - every spec/<SPEC>/ file except spec*.md and acceptance.md (seed data),
#   - SPEC.md: spec.md with {APP} and {STACK} filled in; paste it as the session's first message,
#   - a git repo with one commit "scaffold", so `git diff` shows everything the model changed.
# acceptance.md (expected answers) and spec2.md (the level-2 message) never go into a workspace.
set -euo pipefail

SHADCN="shadcn@4.21.0"                 # pinned so every Base scaffold is the same
# every shadcn component that both registries (shadcn.com and the one bundled in jac) have, so both arms
# start with the same set; picking the right ones is part of the test
UI="accordion alert alert-dialog aspect-ratio avatar badge breadcrumb button button-group calendar card carousel chart checkbox collapsible combobox command context-menu dialog drawer dropdown-menu empty field hover-card input input-group input-otp item kbd label menubar native-select navigation-menu pagination popover progress radio-group resizable scroll-area select separator sheet sidebar skeleton slider sonner spinner switch table tabs textarea toggle toggle-group tooltip"

STACK_Base='React (Vite, TypeScript) frontend in `frontend/` and FastAPI (Python) backend in `backend/`. Both were just created: `frontend/` by `shadcn init -t vite` with Tailwind and every shadcn/ui component in `frontend/src/components/ui/` (`npm install` done), and `backend/` with a minimal FastAPI app in `main.py` and a virtualenv in `backend/.venv` (fastapi and uvicorn installed). Use the shadcn/ui components for the UI.'
STACK_JacLLM='Jac. The project was just created with `jac create --use jac-shadcn` (a full-stack Jac web app with Tailwind and every jac-shadcn component in `components/ui/`; dependencies installed); `AGENTS.md` comes from that scaffold. Use the jac-shadcn components for the UI.'

# opencode model id per arm (provider "unsloth"); override with env, e.g. MODEL_JacLLM=unsloth/ornith-ai/Ornith-1.5-9B-GGUF:Q8_0
# for an untrained Jac arm
MODEL_Base=${MODEL_Base:-"unsloth/ornith-ai/Ornith-1.5-9B-GGUF:Q8_0"}
MODEL_JacLLM=${MODEL_JacLLM:-"unsloth/JacLLM-SFT-Ornith-9B-v1.3A_GGUF:Q8_0"}

ROOT=$(cd "$(dirname "$0")" && pwd)
SPEC=${1:?usage: init.sh <SPEC> [APP]}
APP=${2:-$SPEC}
SPEC_DIR="$ROOT/spec/$SPEC"
[[ -f "$SPEC_DIR/spec.md" ]] || { echo "no $SPEC_DIR/spec.md" >&2; exit 1; }

scaffold_Base() {
    mkdir -p "$1" && cd "$1"
    npx --yes "$SHADCN" init -t vite -b radix -n frontend --no-monorepo -y $UI </dev/null
    mkdir backend
    printf 'fastapi\nuvicorn[standard]\n' > backend/requirements.txt
    cat > backend/main.py <<'EOF'
from fastapi import FastAPI

app = FastAPI()


@app.get("/api/health")
def health():
    return {"ok": True}
EOF
    python3 -m venv backend/.venv
    backend/.venv/bin/pip install -q -r backend/requirements.txt
    printf 'node_modules/\ndist/\n.venv/\n__pycache__/\n' > .gitignore
}

scaffold_JacLLM() {
    mkdir -p "$(dirname "$1")" && cd "$(dirname "$1")"
    jac create "$(basename "$1")" --use jac-shadcn
    (cd "$1" && jac install --shadcn $UI)
}

for ARM in Base JacLLM; do
    DIR="$ROOT/Impl/$ARM/$APP"
    if [[ -e "$DIR" ]]; then echo "skip $ARM: $DIR exists" >&2; continue; fi
    echo "== $ARM -> $DIR"
    ( "scaffold_$ARM" "$DIR" )
    find "$DIR" -mindepth 2 -name .git -prune -exec rm -rf {} +   # shadcn init makes frontend/ its own repo
    find "$SPEC_DIR" -maxdepth 1 -type f ! -name 'spec*.md' ! -name acceptance.md -exec cp {} "$DIR/" \;
    # opencode project config: the global jac MCP off (it would hand both arms Jac docs), and the
    # title/summary model pinned to the arm's model so Studio never swaps models mid-session
    MODEL_VAR="MODEL_$ARM"
    printf '{\n  "$schema": "https://opencode.ai/config.json",\n  "model": "%s",\n  "small_model": "%s",\n  "mcp": { "jac": { "type": "local", "command": ["jac", "mcp"], "enabled": false } }\n}\n' \
        "${!MODEL_VAR}" "${!MODEL_VAR}" > "$DIR/opencode.json"
    STACK_VAR="STACK_$ARM"
    APP="$APP" STACK="${!STACK_VAR}" python3 -c \
        'import os, sys; sys.stdout.write(open(sys.argv[1]).read().replace("{APP}", os.environ["APP"]).replace("{STACK}", os.environ["STACK"]))' \
        "$SPEC_DIR/spec.md" > "$DIR/SPEC.md"
    git -C "$DIR" init -q
    git -C "$DIR" add -A
    git -C "$DIR" commit -qm scaffold
    echo "   $(git -C "$DIR" ls-files | wc -l) files committed"
done

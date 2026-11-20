#!/usr/bin/env bash
# Build the `any` arm's starting project once: scaffold_any.sh <dir>
#
# Same Base scaffold as benchmark/fullstack-ab/init.sh: `shadcn init -t vite` (React, Vite, TypeScript, Tailwind) with
# every shadcn/ui component both registries have, in frontend/ (npm install done), and a FastAPI app in backend/ with
# its virtualenv. Added for the baseline: backend/main.py serves the built frontend at / after the API routes, and
# start.sh builds the frontend and serves the page and the API together on $PORT, so the app starts as it is.
set -euo pipefail
SHADCN="shadcn@4.21.0"
UI="accordion alert alert-dialog aspect-ratio avatar badge breadcrumb button button-group calendar card carousel chart checkbox collapsible combobox command context-menu dialog drawer dropdown-menu empty field hover-card input input-group input-otp item kbd label menubar native-select navigation-menu pagination popover progress radio-group resizable scroll-area select separator sheet sidebar skeleton slider sonner spinner switch table tabs textarea toggle toggle-group tooltip"

D=${1:?usage: scaffold_any.sh <dir>}
mkdir -p "$D" && cd "$D"
npx --yes "$SHADCN" init -t vite -b radix -n frontend --no-monorepo -y $UI </dev/null
find . -mindepth 2 -name .git -prune -exec rm -rf {} +   # shadcn init makes frontend/ its own repo

mkdir -p backend
printf 'fastapi\nuvicorn[standard]\n' > backend/requirements.txt
cat > backend/main.py <<'EOF'
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI()


@app.get("/api/health")
def health():
    return {"ok": True}


# Put API routes above this line, under /api. The built frontend (frontend/dist) is served at /; keep this mount last.
app.mount("/", StaticFiles(directory=Path(__file__).resolve().parent.parent / "frontend" / "dist", html=True), name="frontend")
EOF
# python3 -m venv needs the python3-venv package; where it is missing, uv makes the same virtualenv
if python3 -m venv backend/.venv 2>/dev/null; then
  backend/.venv/bin/pip install -q -r backend/requirements.txt
else
  rm -rf backend/.venv
  uv venv -q backend/.venv && uv pip install -q --python backend/.venv/bin/python -r backend/requirements.txt
fi

cat > start.sh <<'EOF'
#!/bin/sh
# Build the frontend, then serve it and the API together on $PORT (8000 if unset).
set -e
cd "$(dirname "$0")"
(cd frontend && npx vite build --logLevel warn)
cd backend
exec .venv/bin/uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
EOF
chmod +x start.sh
printf 'node_modules/\ndist/\n.venv/\n__pycache__/\n' > .gitignore

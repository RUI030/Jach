#!/usr/bin/env bash
# Every task of one arm, easiest first, for ROUNDS rounds: run_all.sh <arm: any|jac> [rounds, default 3]
# A run whose gate.json already exists is skipped, so the script can be restarted after a crash.
# Same environment as run.sh (MODEL_ID, BASE_URL, OUT_ROOT, ...), plus TASKS: a space-separated list of task ids to
# run instead of every task in jach/tasks (any level), still run in the order given.
set -u
ARM=$1; ROUNDS=${2:-3}
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
MODEL_ID=${MODEL_ID:-ornith-1.5-9b}
OUT_ROOT=${OUT_ROOT:-$REPO/runs/baseline}
TASKS=${TASKS:-}
[ -n "$TASKS" ] || TASKS=$(python3 -c "
import json, glob, os
specs = [json.load(open(p)) for p in glob.glob('$REPO/jach/tasks/*.json')]
print(' '.join(s['id'] for s in sorted(specs, key=lambda s: (s['level'], s['id']))))")
for r in $(seq 1 "$ROUNDS"); do
  for t in $TASKS; do
    [ -s "$OUT_ROOT/$MODEL_ID/$ARM-$t-r$r/gate.json" ] && continue
    "$HERE/run.sh" "$ARM" "$t" "$r"
  done
done

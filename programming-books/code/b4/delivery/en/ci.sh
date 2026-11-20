#!/bin/sh
# stop at the first failing step, and say which
set -e
step() {
  printf '%s: ' "$1"
  shift
  if out=$("$@" 2>&1); then echo "ok"; else echo "FAILED"; echo "$out" | tail -4; echo "pipeline failed at: $STEP"; exit 1; fi
}
STEP="type check";    step "$STEP" npx tsc
STEP="contract tests";    step "$STEP" node --test
# the contract on main: what clients use today
git show main:openapi.yaml > /tmp/openapi.main.yaml
STEP="breaking changes"; step "$STEP" node breaking.ts /tmp/openapi.main.yaml openapi.yaml
echo "pipeline passed"

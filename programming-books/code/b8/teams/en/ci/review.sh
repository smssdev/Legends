#!/bin/sh
# Review the branch's diff with Claude Code; fail the build on any blocker.
set -e
git diff origin/main...HEAD > /tmp/branch.diff 2>/dev/null || git diff main...HEAD > /tmp/branch.diff
claude -p "Review this diff for the café app. Report blockers only: bugs, missing tests for changed behaviour, or money handled wrongly." < /tmp/branch.diff \
  --model claude-opus-5-5 --tools "" --max-budget-usd 0.50 --no-session-persistence \
  --output-format json --json-schema "$(cat review/schema.json)" > review.json
node -e '
  const r = JSON.parse(require("fs").readFileSync("review.json", "utf8"));
  const v = r.structured_output;
  console.log(JSON.stringify(v), `($${r.total_cost_usd.toFixed(4)})`);
  process.exit(r.subtype === "success" && v.ok ? 0 : 1);
'

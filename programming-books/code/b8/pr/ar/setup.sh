$ git init -q -b main && git config core.hooksPath githooks && chmod +x githooks/commit-msg && git add -A && git commit -qm "chore: start" && git log --oneline
b904072 chore: start

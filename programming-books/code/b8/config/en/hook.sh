$ claude -p "The fix is committed. Push it." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   Pushing to main.
  calls  Bash git push origin main
  gets   (error) PreToolUse:Bash hook error: [sh .claude/hooks/no-push.sh]: Pushing is done by a person, after review.
  says   The push was blocked by the project's hook: pushing is done by a person, after review. The commit is ready on the branch.
  turns: 2, denied: 1, cost: $0.1275, success

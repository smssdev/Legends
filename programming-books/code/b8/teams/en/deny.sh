$ node trust.mjs && claude -p "The release is tagged. Push it." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   Pushing.
  calls  Bash git push origin main
  gets   (error) Permission to use Bash with command git push origin main has been denied.
  says   I couldn't push: the team's settings deny it. A person needs to push the release.
  turns: 2, denied: 1, cost: $0.1265, success

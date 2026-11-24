$ claude -p "Run the tests and tell me what fails." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   I'll run the tests.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) This command requires approval
  says   I couldn't run the tests: running `node --test` needs your approval. Allow it, or run it yourself and paste the output.
  turns: 2, denied: 1, cost: $0.1239, success

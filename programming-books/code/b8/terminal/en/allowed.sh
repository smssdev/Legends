$ claude -p "Run the tests and tell me what fails." --model claude-opus-5-5 --no-session-persistence --allowedTools "Bash(node --test)" --output-format stream-json --verbose | node watch.mjs
  says   I'll run the tests.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   One test fails: "a bill with piastres". total("85.50", 10) returns 93.50 instead of 94.05, because parseInt drops the .50 before the tip is added.
  turns: 2, denied: 0, cost: $0.0669, success

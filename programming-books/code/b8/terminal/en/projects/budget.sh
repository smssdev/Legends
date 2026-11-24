$ claude -p "Keep running the tests until they pass." --model claude-opus-5-5 --no-session-persistence --allowedTools "Bash(node --test)" --max-budget-usd 0.30 --output-format stream-json --verbose | node watch.mjs
  says   I'll run the tests.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   Still failing; running them again.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   Still failing; running them again.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   Still failing; running them again.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  gets   (error) ok 1 - a round bill | not ok 2 - a bill with piastres
  says   Still failing; running them again.
  calls  Bash: {"command":"node --test","description":"Run the tests"}
  turns: 5, denied: 0, cost: $0.3291, error_max_budget_usd

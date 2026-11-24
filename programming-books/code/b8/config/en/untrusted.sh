$ claude -p "Run the tests." --model claude-opus-5-5 --no-session-persistence --output-format stream-json --verbose | node watch.mjs
  says   Running the tests.
  calls  Bash node --test
  gets   ok 1 - whole pounds | ok 2 - piastres | ok 3 - zero
  says   All 3 tests pass.
  turns: 2, denied: 0, cost: $0.1273, success

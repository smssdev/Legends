$ claude -p "Fix issue 42 (issues/42.md) on a new branch, with a test, and write the pull request description in PR.md from the template." --model claude-opus-5-5 --no-session-persistence --permission-mode acceptEdits --allowedTools "Bash(cat issues/42.md)" "Bash(git switch -c fix/42-piastres)" "Bash(node --test)" "Bash(git commit:*)" --output-format stream-json --verbose | node watch.mjs
  says   I'll read the issue first.
  calls  Bash cat issues/42.md
  gets   # 42: Bills with piastres are totalled wrong | A customer's bill of 85.50 EGP with a 10% tip showed 
  says   The bill is read wrongly when it has piastres. Creating a branch for the fix.
  calls  Bash git switch -c fix/42-piastres
  gets   Switched to a new branch 'fix/42-piastres'
  says   Reading the code that totals a bill.
  calls  Read src/price.mjs
  gets   1	export const total = (bill, tip) => parseInt(bill) * (1 + tip / 100); | 2
  says   parseInt drops the piastres. Using Number, and adding a test with the issue's example.
  calls  Edit src/price.mjs
  calls  Read test/price.test.mjs
  gets   The file src/price.mjs has been updated successfully. (file state is current in your context — no ne
  gets   1	import test from "node:test"; | 2	import assert from "node:assert/strict";
  calls  Edit test/price.test.mjs
  gets   The file test/price.test.mjs has been updated successfully. (file state is current in your context —
  says   Running the tests.
  calls  Bash node --test
  gets   ok 1 - a round bill | ok 2 - a bill with piastres (issue 42)
  says   Committing.
  calls  Bash git commit -am "fixed stuff"
  gets   (error) Exit code 1 | Commit messages follow Conventional Commits: type(scope): subject
  says   The repository's hook wants Conventional Commits. Committing again with a proper message.
  calls  Bash git commit -am "fix(price): keep piastres when totalling a bill (#42)"
  gets   [fix/42-piastres e043548] fix(price): keep piastres when totalling a bill (#42) | 2 files changed, 2
  says   Writing the description from the template.
  calls  Read .github/pull_request_template.md
  gets   1	## What and why | 2
  calls  Write PR.md
  gets   File created successfully at: PR.md (file state is current in your context — no need to Read it back
  says   Done: branch fix/42-piastres has one commit, the tests pass, and PR.md is ready to paste into the pull request.
  turns: 12, denied: 0, cost: $0.7340, success

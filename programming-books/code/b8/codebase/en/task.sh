$ claude -p "Add 14% VAT to receipts: a subtotal, the VAT, and the total including it. Update the test." --model claude-opus-5-5 --no-session-persistence --permission-mode acceptEdits --allowedTools "Bash(grep -rln total src)" "Bash(node --test)" --output-format stream-json --verbose | node watch.mjs
  says   I'll find where receipts are totalled.
  calls  Bash grep -rln total src
  gets   src/receipt.mjs
  says   Found src/receipt.mjs. Reading it, and the menu module beside it, before I change anything.
  calls  Read src/receipt.mjs
  calls  Read src/menu.mjs
  gets   1	export const PRICES = {
  gets   1	import {priceOf} from "./menu.mjs";
  says   I'll add the VAT after the subtotal.
  calls  Edit src/receipt.mjs
  calls  Edit src/menu.mjs
  gets   The file src/receipt.mjs has been updated successfully. (file stat
  gets   The file src/menu.mjs has been updated successfully. (file state i
  says   Now the test, which still expects the old total.
  calls  Edit test/receipt.test.mjs
  gets   The file test/receipt.test.mjs has been updated successfully.
  says   Running the tests.
  calls  Bash node --test
  gets   ok 1 - a receipt adds up its lines
  says   Done. src/receipt.mjs now returns subtotal, vat (14%, rounded to piastres) and total; VAT_RATE is exported from src/menu.mjs. The test checks all three, and it passes.
  turns: 8, denied: 0, cost: $0.3986, success

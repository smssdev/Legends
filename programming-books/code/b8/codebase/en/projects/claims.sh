$ git checkout -q -- . && claude -p "Add 14% VAT to receipts: a subtotal, the VAT, and the total including it. Update the test." --model claude-opus-5-5 --no-session-persistence --permission-mode acceptEdits --allowedTools "Bash(grep -rln total src)" "Bash(node --test)" | node claims.mjs
claimed: src/menu.mjs, src/receipt.mjs
changed in git: src/menu.mjs, src/receipt.mjs, test/receipt.test.mjs
changed but not mentioned: test/receipt.test.mjs

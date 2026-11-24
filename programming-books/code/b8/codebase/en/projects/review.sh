$ git diff | claude -p "Review this diff." --model claude-opus-5-5 --no-session-persistence --tools ""
1. menu.mjs: VAT_RATE = 0.14 is a good single place for the rate.
2. receipt.mjs: the VAT is rounded to piastres, but total is subtotal + vat without rounding; with other prices the sum can show a floating-point tail: a subtotal of 16 gives a total of 18.240000000000002.
3. The test covers one order; add one whose VAT needs rounding.

$ node stale.mjs
No

The documentation makes claims about specific examples that are not consistent with the actual code behavior.

Specifically:

1. The first example: `linePrice(1000, 9)` → 9000  
   - Code: unit=1000, quantity=9 → full = 9000, quantity < 12 → off = 0 → result = 9000 ✅  
   - This example is correct.

2. The second example: `linePrice(1000, 10)` → 9000  
   - Code: unit=1000, quantity=10 → full = 10000, quantity ≥ 12? No → off = 0 → result = 10000 ❌  
   - Expected: 9000, actual: 10000 → **Incorrect**

3. The third example: `linePrice(6000, 10)` → 55000  
   - Code: unit=6000, quantity=10 → full = 60000, quantity < 12 → off = 0 → result = 60000 ❌  
   - Expected: 55000, actual: 60000 → **Incorrect**

So, two of the examples in the
--- examples run: 2 no longer true
   linePrice(1000, 10) // => 9000   (real: 10000)
   linePrice(6000, 10) // => 55000   (real: 60000)

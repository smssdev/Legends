$ node budget.mjs
1. listFiles {} -> package.json
2. readFile {"path":"test/price.test.mjs"} -> import {test} from "node:test";
3. readFile {"path":"src/price.mjs"} -> // 10% off from the 10th cup, at most 5000 off.
4. writeFile {"path":"src/price.mjs"} -> stopped: step limit
--- the agent: (step limit reached)
--- the tests, run by us: fail

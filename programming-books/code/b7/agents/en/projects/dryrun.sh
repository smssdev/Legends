$ node dryrun.mjs
1. listFiles {} -> package.json
2. readFile {"path":"test/price.test.mjs"} -> import {test} from "node:test";
3. readFile {"path":"src/price.mjs"} -> // 10% off from the 10th cup, at most 5000 off.
4. writeFile {"path":"src/price.mjs"} -> recorded (dry run)
--- cafe4/src/price.mjs	2026-11-23 21:01:25.922602451 +0000
+++ src/price.mjs (proposed)	2026-11-23 21:16:00.756319805 +0000
@@ -1,6 +1,6 @@
 // 10% off from the 10th cup, at most 5000 off.
 export function linePrice(unit, quantity) {
   const full = unit * quantity;
-  const off = quantity > 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
+  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
   return full - off;
 }

--- 1 change(s) proposed, none applied

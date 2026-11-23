$ node review.mjs
--- before
+++ after the agent
@@ -1,6 +1,6 @@
 // 10% off from the 10th cup, at most 5000 off.
 export function linePrice(unit, quantity) {
   const full = unit * quantity;
-  const off = quantity > 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
+  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
   return full - off;
 }

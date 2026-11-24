$ git diff --stat && git diff src/receipt.mjs
 src/menu.mjs          | 2 ++
 src/receipt.mjs       | 7 ++++---
 test/receipt.test.mjs | 4 +++-
 3 files changed, 9 insertions(+), 4 deletions(-)
diff --git a/src/receipt.mjs b/src/receipt.mjs
index 6aef014..4faec27 100644
--- a/src/receipt.mjs
+++ b/src/receipt.mjs
@@ -1,8 +1,9 @@
-import {priceOf} from "./menu.mjs";
+import {priceOf, VAT_RATE} from "./menu.mjs";
 
 // A receipt for an order: one line per item, then the total.
 export function receipt(items) {
   const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
-  const total = lines.reduce((sum, line) => sum + line.amount, 0);
-  return {lines, total};
+  const subtotal = lines.reduce((sum, line) => sum + line.amount, 0);
+  const vat = Math.round(subtotal * VAT_RATE * 100) / 100;
+  return {lines, subtotal, vat, total: subtotal + vat};
 }

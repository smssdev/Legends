import {ask} from "./lib/ask.mjs";

// A diff from a real change, and a request for the reviewer's summary.
const diff = `--- a/src/prices.mjs
+++ b/src/prices.mjs
@@ export function priceOf(drink, size) {
-  return PRICES[drink][size];
+  const price = PRICES[drink]?.[size];
+  if (price === undefined) {
+    return 0;
+  }
+  return price;
 }`;
console.log(await ask(`Explain this change for a reviewer: what it does, and what could go wrong. At most six lines.\n\n${diff}`, {maxTokens: 250}));

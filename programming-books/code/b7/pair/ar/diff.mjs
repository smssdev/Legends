import {ask} from "./lib/ask.mjs";

// فرق من تغيير حقيقي، وطلب ملخص للمراجع.
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
console.log(await ask(`اشرح هذا التغيير لمراجع: ماذا يفعل، وما الذي قد يسوء. ستة أسطر على الأكثر.\n\n${diff}`, {maxTokens: 250}));

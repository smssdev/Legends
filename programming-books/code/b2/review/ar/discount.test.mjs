// code/b2/review/ar/discount.test.ts
import { strict as assert } from "node:assert";

// code/b2/review/ar/cart.ts
function subtotal(lines) {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}

// code/b2/review/ar/discount.ts
var codes = {
  BIT10: { percent: 10 },
  HALF: { percent: 50 }
};
function price(lines, code) {
  const sum = subtotal(lines);
  const key = code?.trim().toUpperCase();
  if (!key) return { ok: true, subtotal: sum, discount: 0, total: sum };
  const found = codes[key];
  if (!found) return { ok: false, reason: "unknown-code" };
  const discount = Math.round(sum * found.percent / 100);
  return { ok: true, subtotal: sum, discount, total: sum - discount };
}

// code/b2/review/ar/discount.test.ts
var cart = [
  { name: "mug", price: 8500, qty: 1 },
  { name: "sticker", price: 1499, qty: 3 }
];
var egp = (piastres) => (piastres / 100).toFixed(2);
for (const code of [void 0, "BIT10", " half ", "NOPE"]) {
  const result = price(cart, code);
  const label = (code === void 0 ? "(\u0628\u0644\u0627 \u0643\u0648\u062F)" : JSON.stringify(code)).padEnd(10);
  if (!result.ok) console.log(`${label} \u2192 \u0643\u0648\u062F \u0645\u062C\u0647\u0648\u0644`);
  else console.log(`${label} \u2192 \u0627\u0644\u0645\u062C\u0645\u0648\u0639 ${egp(result.subtotal)}  \u0627\u0644\u062E\u0635\u0645 ${egp(result.discount)}  \u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A ${egp(result.total)}`);
}
assert.deepEqual(price([], "BIT10"), { ok: true, subtotal: 0, discount: 0, total: 0 });
assert.equal(price(cart, "bit10").ok, true);
assert.deepEqual(price(cart, "FREE"), { ok: false, reason: "unknown-code" });
var before = structuredClone(cart);
price(cart, "HALF");
assert.deepEqual(cart, before);
console.log("\u2713 \u0646\u062C\u062D\u062A 4 \u0641\u062D\u0648\u0635");

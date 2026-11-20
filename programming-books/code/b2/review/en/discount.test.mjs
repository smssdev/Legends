// code/b2/review/en/discount.test.ts
import { strict as assert } from "node:assert";

// code/b2/review/en/cart.ts
function subtotal(lines) {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}

// code/b2/review/en/discount.ts
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

// code/b2/review/en/discount.test.ts
var cart = [
  { name: "mug", price: 8500, qty: 1 },
  { name: "sticker", price: 1499, qty: 3 }
];
var egp = (piastres) => (piastres / 100).toFixed(2);
for (const code of [void 0, "BIT10", " half ", "NOPE"]) {
  const result = price(cart, code);
  const label = (code === void 0 ? "(no code)" : JSON.stringify(code)).padEnd(10);
  if (!result.ok) console.log(`${label} \u2192 unknown code`);
  else console.log(`${label} \u2192 subtotal ${egp(result.subtotal)}  discount ${egp(result.discount)}  total ${egp(result.total)}`);
}
assert.deepEqual(price([], "BIT10"), { ok: true, subtotal: 0, discount: 0, total: 0 });
assert.equal(price(cart, "bit10").ok, true);
assert.deepEqual(price(cart, "FREE"), { ok: false, reason: "unknown-code" });
var before = structuredClone(cart);
price(cart, "HALF");
assert.deepEqual(cart, before);
console.log("\u2713 4 checks passed");

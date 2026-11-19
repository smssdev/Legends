import { strict as assert } from "node:assert";
import { price } from "./discount";

const cart = [
  { name: "mug", price: 8500, qty: 1 },
  { name: "sticker", price: 1499, qty: 3 },
];
const egp = (piastres: number) => (piastres / 100).toFixed(2);

for (const code of [undefined, "BIT10", " half ", "NOPE"]) {
  const result = price(cart, code);
  const label = (code === undefined ? "(no code)" : JSON.stringify(code)).padEnd(10);
  if (!result.ok) console.log(`${label} → unknown code`);
  else console.log(`${label} → subtotal ${egp(result.subtotal)}  discount ${egp(result.discount)}  total ${egp(result.total)}`);
}

// The cases that matter, as checks that fail loudly
assert.deepEqual(price([], "BIT10"), { ok: true, subtotal: 0, discount: 0, total: 0 });
assert.equal(price(cart, "bit10").ok, true);
assert.deepEqual(price(cart, "FREE"), { ok: false, reason: "unknown-code" });
const before = structuredClone(cart);
price(cart, "HALF");
assert.deepEqual(cart, before);
console.log("✓ 4 checks passed");

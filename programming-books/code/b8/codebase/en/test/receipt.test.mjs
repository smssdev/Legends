import test from "node:test";
import assert from "node:assert/strict";
import {receipt} from "../src/receipt.mjs";

test("a receipt adds up its lines", () => {
  const r = receipt([{name: "latte", qty: 2}, {name: "croissant", qty: 1}]);
  assert.equal(r.total, 120);
});

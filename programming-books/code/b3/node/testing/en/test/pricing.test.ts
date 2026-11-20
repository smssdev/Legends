import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { total } from "../src/pricing.ts";

const kit = { price: 45000, quantity: 1 };
const wheels = { price: 6000, quantity: 2 };

describe("total", () => {
  // one row per case: adding a case is one line
  const cases = [
    {
      name: "no code: subtotal plus VAT",
      code: undefined,
      want: { discount: 0, vat: 7980, total: 64980 },
    },
    {
      name: "SAVE10 takes 10% off",
      code: "SAVE10",
      want: { discount: 5700, vat: 7182, total: 58482 },
    },
    {
      name: "FIXED50 takes 50 pounds off",
      code: "FIXED50",
      want: { discount: 5000, vat: 7280, total: 59280 },
    },
  ];
  for (const c of cases) {
    it(c.name, () => {
      assert.partialDeepStrictEqual(total([kit, wheels], c.code), c.want);
    });
  }

  it("a fixed discount never goes below zero", () => {
    const cheap = [{ price: 3000, quantity: 1 }];
    assert.deepEqual(total(cheap, "FIXED50"), {
      subtotal: 3000,
      discount: 3000,
      vat: 0,
      total: 0,
    });
  });

  it("refuses an unknown code", () => {
    assert.throws(() => total([kit], "FREE"), /FREE/);
  });
});

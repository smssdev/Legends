import { describe, expect, it } from "vitest";
import { cartTotal, formatPrice } from "./price";

describe("formatPrice", () => {
  it("ينسّق السعر بمنزلتين عشريتين والعملة", () => {
    expect(formatPrice(8)).toBe("8.00 جنيهاً");
    expect(formatPrice(19.5)).toBe("19.50 جنيهاً");
  });
});

describe("cartTotal", () => {
  const lines = [
    { price: 25, quantity: 1 },
    { price: 8, quantity: 2 },
  ];

  it("يجمع أسطر السلة", () => {
    expect(cartTotal(lines)).toBe(41);
  });

  it("يُرجع 0 للسلة الفارغة", () => {
    expect(cartTotal([])).toBe(0);
  });

  it.each([
    ["WELCOME10", 41, 36.9],
    ["SPRING25", 41, 30.75],
  ])("يطبّق الكوبون %s على مجموع %s: %s", (coupon, _total, expected) => {
    expect(cartTotal(lines, coupon)).toBe(expected);
  });

  it("يتجاهل الكوبون المجهول", () => {
    expect(cartTotal(lines, "FREE100")).toBe(41);
  });

  it("يرفض الكمية السالبة", () => {
    expect(() => cartTotal([{ price: 8, quantity: -1 }])).toThrow(RangeError);
  });
});

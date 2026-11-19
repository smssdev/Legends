import { describe, expect, it } from "vitest";
import { cartTotal, formatPrice } from "./price";

describe("formatPrice", () => {
  it("formats a price with two decimals and the currency", () => {
    expect(formatPrice(8)).toBe("8.00 EGP");
    expect(formatPrice(19.5)).toBe("19.50 EGP");
  });
});

describe("cartTotal", () => {
  const lines = [
    { price: 25, quantity: 1 },
    { price: 8, quantity: 2 },
  ];

  it("adds the lines of a cart", () => {
    expect(cartTotal(lines)).toBe(41);
  });

  it("returns 0 for an empty cart", () => {
    expect(cartTotal([])).toBe(0);
  });

  it.each([
    ["WELCOME10", 41, 36.9],
    ["SPRING25", 41, 30.75],
  ])("applies the coupon %s to a total of %s: %s", (coupon, _total, expected) => {
    expect(cartTotal(lines, coupon)).toBe(expected);
  });

  it("ignores an unknown coupon", () => {
    expect(cartTotal(lines, "FREE100")).toBe(41);
  });

  it("refuses a negative quantity", () => {
    expect(() => cartTotal([{ price: 8, quantity: -1 }])).toThrow(RangeError);
  });
});

import { subtotal, type Line } from "./cart";

// Prices are whole piastres: no floating-point money
// The codes live in one table; adding a code needs no new if
const codes: Record<string, { percent: number }> = {
  BIT10: { percent: 10 },
  HALF: { percent: 50 },
};

// Unknown codes are an answer, not a silent full price
export type Priced =
  | { ok: true; subtotal: number; discount: number; total: number }
  | { ok: false; reason: "unknown-code" };

// The cart is not changed: the function returns a new result
export function price(lines: readonly Line[], code?: string): Priced {
  const sum = subtotal(lines);
  const key = code?.trim().toUpperCase();
  if (!key) return { ok: true, subtotal: sum, discount: 0, total: sum };
  const found = codes[key];
  if (!found) return { ok: false, reason: "unknown-code" };
  const discount = Math.round((sum * found.percent) / 100);
  return { ok: true, subtotal: sum, discount, total: sum - discount };
}

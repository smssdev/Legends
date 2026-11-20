// pure: the same input always gives the same output, and nothing else happens
export type Line = { price: number; quantity: number };

const CODES: Record<string, { percent?: number; amount?: number }> = {
  SAVE10: { percent: 10 },
  FIXED50: { amount: 5000 },
};

export function total(lines: Line[], code?: string) {
  const subtotal = lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
  let discount = 0;
  if (code) {
    // discount codes: a percentage off, or a fixed amount (never below zero)
    const rule = CODES[code];
    if (!rule) throw new Error(`unknown discount code: ${code}`);
    discount = rule.percent
      ? Math.round((subtotal * rule.percent) / 100)
      : rule.amount!;
    discount = Math.min(discount, subtotal);
  }
  // VAT of 14% on the discounted subtotal, rounded to the nearest piastre
  // exercise 1: a bug to find, switched on with BUG=1
  const rate = process.env.BUG ? 0.15 : 0.14;
  const vat = Math.round((subtotal - discount) * rate);
  return { subtotal, discount, vat, total: subtotal - discount + vat };
}

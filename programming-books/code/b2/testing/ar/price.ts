export type Line = { price: number; quantity: number };

const COUPONS: Record<string, number> = { WELCOME10: 10, SPRING25: 25 };

export function formatPrice(value: number): string {
  return `${value.toFixed(2)} جنيهاً`;
}

export function cartTotal(lines: Line[], coupon?: string): number {
  if (lines.some((l) => l.quantity < 0)) throw new RangeError("quantity must not be negative");
  const sum = lines.reduce((total, l) => total + l.price * l.quantity, 0);
  const percent = coupon ? (COUPONS[coupon] ?? 0) : 0;
  return Math.round(sum * (100 - percent)) / 100;
}

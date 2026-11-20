// the domain: the shop's rules, in plain TypeScript; no database, no HTTP, no framework
export type Line = { productId: number; quantity: number; price: number };
export type Order = {
  id: number;
  email: string;
  lines: Line[];
  total: number;
  placedAt: Date;
};

// errors that speak the business's language; each adapter decides what they become
export class OrderError extends Error {}
export class TooMany extends OrderError {}
export class OutOfStock extends OrderError {}
export class UnknownProduct extends OrderError {}

// a rule of the business, not of the database or the API
export const MAX_PER_PRODUCT = 10;

export function checkQuantities(items: { productId: number; quantity: number }[]) {
  for (const item of items) {
    if (item.quantity > MAX_PER_PRODUCT)
      throw new TooMany("At most 10 of one product per order");
  }
}

export const totalOf = (lines: Line[]) =>
  lines.reduce((sum, l) => sum + l.price * l.quantity, 0);

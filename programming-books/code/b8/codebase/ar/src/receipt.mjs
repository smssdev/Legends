import {priceOf} from "./menu.mjs";

// A receipt for an order: one line per item, then the total.
export function receipt(items) {
  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
  const total = lines.reduce((sum, line) => sum + line.amount, 0);
  return {lines, total};
}

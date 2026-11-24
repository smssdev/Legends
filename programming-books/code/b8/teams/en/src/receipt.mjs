import {priceOf} from "./menu.mjs";

export function receipt(items) {
  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
  const total = lines.reduce((sum, line) => sum + line.amount, 0);
  return {lines, total};
}

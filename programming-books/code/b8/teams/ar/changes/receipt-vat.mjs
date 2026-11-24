import {priceOf, VAT_RATE} from "./menu.mjs";

export function receipt(items) {
  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
  const subtotal = lines.reduce((sum, line) => sum + line.amount, 0);
  const vat = Math.round(subtotal * VAT_RATE * 100) / 100;
  return {lines, subtotal, vat, total: subtotal + vat};
}

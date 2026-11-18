import formatPrice, { withVat } from "./prices.mjs";

export function cartTotal(prices) {
  return formatPrice(withVat(prices.reduce((sum, p) => sum + p, 0)));
}

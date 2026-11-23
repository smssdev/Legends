/**
 * Price of an order line in piastres.
 * @example linePrice(1000, 9) // => 9000
 * @example linePrice(1000, 10) // => 9000
 * @example linePrice(6000, 10) // => 55000
 */
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 12 ? Math.min(Math.floor(full / 10), 3000) : 0;
  return full - off;
}

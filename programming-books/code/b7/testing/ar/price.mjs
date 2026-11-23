// Price of an order line in piastres: unit price times quantity,
// 10% off from the 10th cup, and never more than 5000 off.
// Examples: linePrice(1000, 9) is 9000; linePrice(1000, 10) is 9000;
// linePrice(6000, 10) is 55000.
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
  return full - off;
}

// Price of an order line in piastres: unit price times quantity,
// 10% off from the 10th cup, and never more than 5000 off.
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
  return full - off;
}

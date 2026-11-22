$ node complete.mjs
--- raw:
  let total = 0;
  for (const item of items) {
    total += item.price * item.quantity;
  }
  return total * (1 + taxRate);
}

--- stopped at the block's end:
  let total = 0;
  for (const item of items) {
    total += item.price * item.quantity;
  }
  return total * (1 + taxRate);

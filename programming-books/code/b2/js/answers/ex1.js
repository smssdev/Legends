const cart = { items: [{ id: 1, qty: 1 }, { id: 2, qty: 3 }], coupon: null };

function removeItem(cart, id) {
  return { ...cart, items: cart.items.filter((item) => item.id !== id) };
}

const next = removeItem(cart, 1);
console.log(cart.items.length, next.items.length, cart === next);

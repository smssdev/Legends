const cart = { items: [{ id: 1, qty: 1 }], coupon: null };

// Return a new object instead of changing the old one
function addOne(cart, id) {
  return {
    ...cart,
    items: cart.items.map((item) =>
      item.id === id ? { ...item, qty: item.qty + 1 } : item,
    ),
  };
}

const next = addOne(cart, 1);
console.log(cart.items[0].qty, next.items[0].qty);
console.log(cart === next, cart.items === next.items);

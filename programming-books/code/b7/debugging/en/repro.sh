$ node repro.mjs
--- repro/attempt.mjs
const orders = [];

function priceOf(order) {
  return order.price;
}

function total() {
  return orders.reduce((sum, order) => sum + priceOf(order), 0);
}

total();

wanted: (no error)
got:    (no error)
same error: a reproduction

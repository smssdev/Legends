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

wanted: TypeError: Cannot read properties of undefined (reading 'price')
got:    (no error)
different: not a reproduction yet

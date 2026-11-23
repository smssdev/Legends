$ node repro.mjs
--- repro/attempt.mjs
const orders = [ { id: 41, price: 900 } ];

function priceOf(order) {
  return order.price;
}

function total(orders) {
  return orders.reduce((sum, order) => sum + priceOf(order), 0);
}

console.log(total(orders));

wanted: TypeError: Cannot read properties of undefined (reading 'price')
got:    (no error)
different: not a reproduction yet

const orders = [
  { id: 1, customer: { name: "عمر" }, total: 40 },
  { id: 2, total: 15 },
  { id: 3, customer: { name: "هدى" }, total: 22 },
];

function label(order) {
  return `#${order.id} ${order.customer.name}: ${order.total}`;
}

function printAll(list) {
  for (const order of list) {
    console.log(label(order));
  }
}

printAll(orders);

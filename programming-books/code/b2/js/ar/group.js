const orders = [
  { id: 1, status: "paid", total: 40 },
  { id: 2, status: "pending", total: 15 },
  { id: 3, status: "paid", total: 22 },
  { id: 4, status: "refunded", total: 9 },
];

const byStatus = Object.groupBy(orders, (order) => order.status);
console.log(Object.keys(byStatus));

const totals = Object.fromEntries(
  Object.entries(byStatus).map(([status, list]) => [
    status,
    list.reduce((sum, order) => sum + order.total, 0),
  ]),
);
console.log(totals);

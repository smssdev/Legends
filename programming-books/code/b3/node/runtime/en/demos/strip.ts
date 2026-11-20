type Order = { id: number; total: number };

// a string: wrong, and nobody checks
const order: Order = { id: 1, total: "450" };
console.log(order.total + 50);

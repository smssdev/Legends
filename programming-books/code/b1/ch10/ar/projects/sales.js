const orders = [
  { product: "كتاب", quantity: 2, price: 25 },
  { product: "ملصق", quantity: 5, price: 3 },
  { product: "كوب", quantity: 1, price: 8 },
  { product: "كتاب", quantity: 1, price: 25 },
  { product: "ملصق", quantity: 10, price: 3 },
];

const lineTotal = (order) => order.quantity * order.price;

const revenue = orders.map(lineTotal).reduce((sum, value) => sum + value, 0);
const bigOrders = orders.filter((order) => lineTotal(order) >= 25);
const stickersSold = orders
  .filter((order) => order.product === "ملصق")
  .reduce((sum, order) => sum + order.quantity, 0);

console.log("الإيرادات:", revenue);
console.log("طلبات بقيمة 25 أو أكثر:", bigOrders.length);
console.log("الملصقات المبيعة:", stickersSold);

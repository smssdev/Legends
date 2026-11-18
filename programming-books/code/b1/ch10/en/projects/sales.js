const orders = [
  { product: "book", quantity: 2, price: 25 },
  { product: "sticker", quantity: 5, price: 3 },
  { product: "mug", quantity: 1, price: 8 },
  { product: "book", quantity: 1, price: 25 },
  { product: "sticker", quantity: 10, price: 3 },
];

const lineTotal = (order) => order.quantity * order.price;

const revenue = orders.map(lineTotal).reduce((sum, value) => sum + value, 0);
const bigOrders = orders.filter((order) => lineTotal(order) >= 25);
const stickersSold = orders
  .filter((order) => order.product === "sticker")
  .reduce((sum, order) => sum + order.quantity, 0);

console.log("Revenue:", revenue);
console.log("Orders of 25 or more:", bigOrders.length);
console.log("Stickers sold:", stickersSold);

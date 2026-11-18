const prices = [12, 5, 30, 8];
let total = 0;

for (const price of prices) {
  total = total + price;
}

console.log(`Items: ${prices.length}`);
console.log(`Total: ${total}`);
console.log(`Average: ${total / prices.length}`);

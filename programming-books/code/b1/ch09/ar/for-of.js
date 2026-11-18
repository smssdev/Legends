const prices = [12, 5, 30, 8];
let total = 0;

for (const price of prices) {
  total = total + price;
}

console.log(`عدد الأصناف: ${prices.length}`);
console.log(`المجموع: ${total}`);
console.log(`المتوسط: ${total / prices.length}`);

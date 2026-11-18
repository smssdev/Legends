const prices = [42, 18, 35, 9, 27];
let cheapest = prices[0];

for (const price of prices) {
  if (price < cheapest) {
    cheapest = price;
  }
}

console.log(`أرخص سعر هو ${cheapest}`);

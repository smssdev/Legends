const greeting = "مرحباً";

export function total(prices: any[]) {
  let sum = 0;
  for (const price of prices) {
    if (price == null) continue;
    sum += price;
  }
  return sum;
}

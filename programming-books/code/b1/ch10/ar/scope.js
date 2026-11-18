const tax = 0.14;

function withTax(price) {
  const total = price + price * tax;
  return total;
}

console.log(withTax(100));
console.log(typeof total);

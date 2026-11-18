const double = (n) => n * 2;
console.log(double(21));

const prices = [12, 5, 30, 8];

const withVat = prices.map((p) => p * 1.1);
console.log(withVat);

const cheap = prices.filter((p) => p < 10);
console.log(cheap);

const total = prices.reduce((sum, p) => sum + p, 0);
console.log(total);

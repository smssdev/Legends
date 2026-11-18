const age = 9;
let price;

if (age < 4) {
  price = 0;
} else if (age < 13) {
  price = 6;
} else if (age >= 65) {
  price = 7;
} else {
  price = 10;
}

console.log(`العمر ${age}: السعر ${price}$`);

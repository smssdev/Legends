// Ages of the visitors waiting in line
const queue = [34, 9, 2, 70, 16, 41, 3];

let total = 0;
let freeTickets = 0;
const receipt = [];

for (const age of queue) {
  let price;
  if (age < 4) {
    price = 0;
    freeTickets++;
  } else if (age < 13 || age >= 65) {
    price = 6;
  } else {
    price = 10;
  }
  total = total + price;
  receipt.push(price);
}

console.log(`Visitors served: ${queue.length}`);
console.log(`Prices: ${receipt.join(", ")}`);
console.log(`Free tickets: ${freeTickets}`);
console.log(`Total: ${total}`);

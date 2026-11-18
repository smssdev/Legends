// أعمار الزوار في الطابور
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

console.log(`عدد الزوار: ${queue.length}`);
console.log(`الأسعار: ${receipt.join("، ")}`);
console.log(`تذاكر مجانية: ${freeTickets}`);
console.log(`المجموع: ${total}`);

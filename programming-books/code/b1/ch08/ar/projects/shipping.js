const weight = 3.5; // kg
const express = true;
const city = "الإسكندرية";
const orderTotal = 640;

let cost;
if (weight <= 1) {
  cost = 30;
} else if (weight <= 5) {
  cost = 50;
} else {
  cost = 50 + Math.ceil(weight - 5) * 10;
}

if (express) {
  cost = cost * 2;
}

if (city !== "القاهرة" && city !== "الإسكندرية") {
  cost = cost + 20;
}

const free = orderTotal >= 1000 && !express;
console.log(`الوزن: ${weight} كجم، سريع: ${express}، المدينة: ${city}`);
console.log(free ? "الشحن: مجاني!" : `الشحن: ${cost}`);

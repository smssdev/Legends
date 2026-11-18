const weight = 3.5; // kg
const express = true;
const city = "Alexandria";
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

if (city !== "Cairo" && city !== "Alexandria") {
  cost = cost + 20;
}

const free = orderTotal >= 1000 && !express;
console.log(`Weight: ${weight} kg, express: ${express}, city: ${city}`);
console.log(free ? "Shipping: free!" : `Shipping: ${cost}`);

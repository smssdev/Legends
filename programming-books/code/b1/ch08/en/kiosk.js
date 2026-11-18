// Ticket kiosk: change these values and run again.
const age = 34;
const isMember = true;
const day = "Tuesday";
const showTime = 22; // 24-hour clock

let price;
if (age < 4) {
  price = 0;
} else if (age < 13 || age >= 65) {
  price = 6;
} else {
  price = 10;
}

if (isMember && day === "Tuesday") {
  price = price / 2;
}

if (showTime >= 22 && price > 0) {
  price = price - 1;
}

const message = price === 0 ? "Free entry" : `Please pay $${price}`;
console.log(message);

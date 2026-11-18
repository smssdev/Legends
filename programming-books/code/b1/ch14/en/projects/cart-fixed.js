// Prices arrive as text, as they do from a form or a file
const prices = ["120", "45", "35"];
const discount = 20;

function total(list) {
  let sum = 0;
  for (let i = 0; i < list.length; i++) {
    sum = sum + Number(list[i]);
  }
  return sum;
}

const before = total(prices);
console.log("Total:", before);
console.log("After discount:", before - discount);

function ticketPrice(age) {
  if (age < 4) {
    return 0;
  }
  if (age < 13 || age >= 65) {
    return 6;
  }
  return 10;
}

console.log(ticketPrice(2));
console.log(ticketPrice(9));
console.log(ticketPrice(34));
console.log(ticketPrice(70));

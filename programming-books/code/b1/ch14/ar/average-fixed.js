function average(numbers) {
  let total = 0;
  for (const number of numbers) {
    total = total + number;
  }
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
console.log(average([7]));

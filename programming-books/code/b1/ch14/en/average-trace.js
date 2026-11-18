function average(numbers) {
  let total = 0;
  for (let i = 1; i < numbers.length; i++) {
    console.log("i =", i, "number =", numbers[i], "total =", total);
    total = total + numbers[i];
  }
  console.log("final total:", total);
  return total / numbers.length;
}

console.log(average([10, 20, 30]));
